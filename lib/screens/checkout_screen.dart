import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/address_provider.dart';
import '../providers/restaurant_provider.dart';
import '../services/checkout_service.dart';
import '../services/razorpay_checkout/razorpay_payment_service.dart';
import '../theme/app_theme.dart';
import '../models/address_model.dart';
import 'saved_addresses_screen.dart';
import 'order_success_screen.dart';
import 'payment_confirmation_screen.dart';

enum PaymentChoice { upi, cod }

// Must match the `region=` set on every function in backend/functions/main.py.
const String _functionsRegion = 'asia-south1';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentChoice _payment = PaymentChoice.upi;
  bool _placing = false;

  // An order created on the server but not paid yet. It is only reused for a
  // retry if the cart, coupon, address and payment choice are exactly the same;
  // otherwise the customer would pay for an old, different order.
  String? _pendingOrderId;
  String? _pendingOrderSignature;

  String _orderSignature(CartProvider cart, AddressModel address) {
    return jsonEncode({
      'items': cart.items.values.map((c) => c.toOrderMap()).toList(),
      'coupon': cart.appliedCoupon?.code,
      'address': address.fullAddress,
      'lat': address.latitude,
      'lng': address.longitude,
      'payment': _payment.name,
    });
  }

  Map<String, dynamic>? _previewData;
  String? _lastPreviewAddressId;
  double? _lastPreviewSubtotal;
  Timer? _debounceTimer;

  void _schedulePreviewFetch(AddressModel address, double subtotal) {
    if (_lastPreviewAddressId == address.id && _lastPreviewSubtotal == subtotal) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchPreview(address, subtotal);
    });
  }

  Future<void> _fetchPreview(AddressModel address, double subtotal) async {
    _lastPreviewAddressId = address.id;
    _lastPreviewSubtotal = subtotal;

    try {
      final preview = await CheckoutService.getCheckoutPreview(
        latitude: address.latitude,
        longitude: address.longitude,
        subtotal: subtotal,
      );

      if (mounted) {
        setState(() {
          _previewData = {
            'is_available': preview.isAvailable,
            'status_code': preview.statusCode,
            'status_message': preview.statusMessage,
            'distance_km': preview.distanceKm,
            'delivery_fee': preview.deliveryFee,
            'is_deliverable': preview.isDeliverable,
            'delivery_message': preview.deliveryMessage,
            'minimum_order_value': preview.minimumOrderValue,
            'meets_minimum_order': preview.meetsMinimumOrder,
            'minimum_order_message': preview.minimumOrderMessage,
          };
        });

        context.read<CartProvider>().setPreviewResult(
          deliveryFee: preview.deliveryFee,
          minimumOrderValue: preview.minimumOrderValue,
          failed: false,
        );
      }
    } catch (_) {
      if (mounted) {
        context.read<CartProvider>().setPreviewResult(
          deliveryFee: 30.0,
          minimumOrderValue: 150.0,
          failed: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final restaurant = context.watch<RestaurantProvider>();
    final selectedAddress = addressProvider.selectedAddress;

    if (selectedAddress != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _schedulePreviewFetch(selectedAddress, cart.subtotal);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.maroon,
        iconTheme: const IconThemeData(color: AppColors.gold),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!restaurant.isAcceptingOrders) ...[
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 20.r),
                    10.horizontalSpace,
                    Expanded(
                      child: Text(
                        'Ordering is currently unavailable (${restaurant.unavailableReason}). Checkout is disabled.',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              16.verticalSpace,
            ],

            // 1. Delivery Address Header & Card
            _buildSectionHeader(
              icon: Icons.location_on,
              title: 'Delivery Address',
              trailing: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
                ),
                icon: Icon(
                  selectedAddress == null ? Icons.add_location_alt_outlined : Icons.edit_outlined,
                  size: 16.r,
                  color: AppColors.maroon,
                ),
                label: Text(
                  selectedAddress == null ? 'Add Address' : 'Change',
                  style: TextStyle(
                    color: AppColors.maroon,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
            8.verticalSpace,
            _buildAddressSection(context, selectedAddress, addressProvider.addresses),
            20.verticalSpace,

            // 2. Order Summary Preview Card
            _buildSectionHeader(
              icon: Icons.shopping_bag_outlined,
              title: 'Order Items (${cart.itemCount})',
            ),
            8.verticalSpace,
            _buildOrderItemsCard(cart),
            20.verticalSpace,

            // 3. Payment Method Section
            _buildSectionHeader(
              icon: Icons.payment_outlined,
              title: 'Payment Method',
            ),
            8.verticalSpace,
            _buildPaymentMethodCard(),
            20.verticalSpace,

            // 4. Detailed Bill Summary
            _buildSectionHeader(
              icon: Icons.receipt_long_outlined,
              title: 'Bill Summary',
            ),
            8.verticalSpace,
            _buildBillSummaryCard(cart),
            80.verticalSpace, // Padding for bottom sticky bar
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomPayBar(cart),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18.r, color: AppColors.maroon),
            8.horizontalSpace,
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildAddressSection(
      BuildContext context,
      AddressModel? selectedAddress,
      List<AddressModel> allAddresses,
      ) {
    if (allAddresses.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 24.r),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No delivery address found',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                      color: AppColors.error,
                    ),
                  ),
                  2.verticalSpace,
                  Text(
                    'Please add a delivery address to proceed.',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (selectedAddress == null) {
      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: const Center(child: Text('Please select an address')),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.maroon.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12.r,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.maroon.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: const Icon(Icons.home_outlined, color: AppColors.maroon),
          ),
          14.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      selectedAddress.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                        color: AppColors.textDark,
                      ),
                    ),
                    8.horizontalSpace,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.maroon,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'SELECTED',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                4.verticalSpace,
                Text(
                  selectedAddress.fullAddress,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.grey,
                    height: 1.3,
                  ),
                ),
                6.verticalSpace,
                Text(
                  'Contact: ${selectedAddress.recipientName} (${selectedAddress.recipientPhone})',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard(CartProvider cart) {
    final items = cart.items.values.toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.maroon.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12.r,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(
          color: AppColors.grey.withValues(alpha: 0.15),
          height: 16.h,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.r),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: item.isVeg ? AppColors.success : AppColors.error,
                    width: 1.w,
                  ),
                  borderRadius: BorderRadius.circular(2.r),
                ),
                child: Icon(
                  Icons.circle,
                  size: 6.r,
                  color: item.isVeg ? AppColors.success : AppColors.error,
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                '${item.quantity} x ₹${item.unitPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.grey,
                ),
              ),
              12.horizontalSpace,
              Text(
                '₹${item.total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.maroon.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12.r,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          RadioListTile<PaymentChoice>(
            value: PaymentChoice.upi,
            groupValue: _payment,
            activeColor: AppColors.maroon,
            onChanged: (val) {
              if (val != null) setState(() => _payment = val);
            },
            title: Text(
              'Online Payment (Razorpay / UPI / Cards)',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            subtitle: Text(
              'Fast & secure payment via GPay, PhonePe, Cards, NetBanking',
              style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
            ),
            secondary: Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.maroon,
              size: 22.r,
            ),
          ),
          Divider(color: AppColors.grey.withValues(alpha: 0.15), height: 1),
          RadioListTile<PaymentChoice>(
            value: PaymentChoice.cod,
            groupValue: _payment,
            activeColor: AppColors.maroon,
            onChanged: (val) {
              if (val != null) setState(() => _payment = val);
            },
            title: Text(
              'Cash on Delivery',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            subtitle: Text(
              'Pay with cash or UPI upon delivery',
              style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
            ),
            secondary: Icon(
              Icons.payments_outlined,
              color: AppColors.maroon,
              size: 22.r,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillSummaryCard(CartProvider cart) {
    final double deliveryFee = _previewData?['delivery_fee']?.toDouble() ?? cart.deliveryFee;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.maroon.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 12.r,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _billRow('Item Subtotal', cart.subtotal),
          if (cart.couponDiscount > 0)
            _billRow('Coupon Discount', -cart.couponDiscount, isDiscount: true),
          _billRow('Delivery Fee', deliveryFee),
          Divider(color: AppColors.grey.withValues(alpha: 0.15), height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'To Pay',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '₹${((cart.subtotal - cart.couponDiscount) + deliveryFee).toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.maroon,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDiscount ? AppColors.success : AppColors.grey,
              fontWeight: isDiscount ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount < 0 ? "-" : ""}₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12.sp,
              color: isDiscount ? AppColors.success : AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPayBar(CartProvider cart) {
    final restaurant = context.watch<RestaurantProvider>();
    final bool isAccepting = restaurant.isAcceptingOrders;
    final double minOrderValue = cart.minimumOrderValue;
    final bool meetsMinOrder = cart.subtotal >= minOrderValue;
    final bool isDeliverable = _previewData?['is_deliverable'] ?? true;
    final bool isAvailable = _previewData?['is_available'] ?? true;

    // If preview call failed, do not block the customer — place_order handles server-side enforcement
    final bool canPlace = cart.previewFailed || (meetsMinOrder && isDeliverable && isAvailable);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 20.r,
            offset: const Offset(0, -6),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL PAYABLE',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  2.verticalSpace,
                  Text(
                    '₹${cart.totalPayable.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.maroon,
                    ),
                  ),
                  if (cart.couponDiscount > 0)
                    Text(
                      'Saved ₹${cart.couponDiscount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            16.horizontalSpace,
            Expanded(
              child: SizedBox(
                height: 52.h,
                child: ElevatedButton(
                  onPressed: (_placing || !canPlace || !isAccepting) ? null : () => _placeOrder(context, cart),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAccepting ? AppColors.maroon : Colors.grey.shade400,
                    foregroundColor: AppColors.gold,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: _placing
                      ? SizedBox(
                    height: 22.h,
                    width: 22.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5.w,
                      color: AppColors.gold,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        !isAccepting
                            ? (restaurant.statusType == RestaurantStatusType.paused
                            ? 'TEMPORARILY UNAVAILABLE'
                            : 'RESTAURANT CLOSED')
                            : (_payment == PaymentChoice.upi ? 'Pay via UPI' : 'Place Order'),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                      if (isAccepting) ...[
                        6.horizontalSpace,
                        Icon(
                          _payment == PaymentChoice.upi
                              ? Icons.arrow_forward_rounded
                              : Icons.check_circle_outline,
                          size: 18.r,
                          color: AppColors.gold,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, CartProvider cart) async {
    final selectedAddress = context.read<AddressProvider>().selectedAddress;
    final restaurant = context.read<RestaurantProvider>();

    if (!restaurant.isAcceptingOrders) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Ordering is currently unavailable (${restaurant.unavailableReason}).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before placing an order.')),
      );
      return;
    }

    setState(() => _placing = true);

    try {
      // 1. Get server preview & validate BEFORE creating the order
      final preview = await CheckoutService.getCheckoutPreview(
        latitude: selectedAddress.latitude,
        longitude: selectedAddress.longitude,
        subtotal: cart.subtotal,
      );

      if (!preview.isAvailable) {
        if (!context.mounted) return;
        setState(() => _placing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(preview.statusMessage.isNotEmpty
                ? preview.statusMessage
                : 'Restaurant is currently unavailable.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (!preview.isDeliverable) {
        if (!context.mounted) return;
        setState(() => _placing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(preview.deliveryMessage.isNotEmpty
                ? preview.deliveryMessage
                : 'Address is outside our delivery area.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (!preview.meetsMinimumOrder) {
        if (!context.mounted) return;
        setState(() => _placing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(preview.minimumOrderMessage.isNotEmpty
                ? preview.minimumOrderMessage
                : 'Minimum order value requirement not met.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      cart.setPreviewResult(
        deliveryFee: preview.deliveryFee,
        minimumOrderValue: preview.minimumOrderValue,
        failed: false,
      );

      final calculatedServerTotal = (cart.subtotal - cart.couponDiscount) + preview.deliveryFee;
      final currentShownTotal = cart.totalPayable;

      // Price update confirmation BEFORE order creation
      if ((calculatedServerTotal - currentShownTotal).abs() > 0.50) {
        if (!context.mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Order Total Updated'),
            content: Text(
              'The final order total from the server is ₹${calculatedServerTotal.toStringAsFixed(0)} '
                  '(Delivery Fee: ₹${preview.deliveryFee.toStringAsFixed(0)}).\n\n'
                  'Do you want to proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );

        if (confirm != true) {
          setState(() => _placing = false);
          return;
        }
      }

      // 2. Place order on the server (authoritative creation)
      final functions = FirebaseFunctions.instanceFor(region: _functionsRegion);
      final signature = _orderSignature(cart, selectedAddress);
      String orderId;
      if (_pendingOrderId != null && _pendingOrderSignature == signature) {
        orderId = _pendingOrderId!;
      } else {
        final result = await functions.httpsCallable('place_order').call({
          'items': cart.items.values.map((c) => c.toOrderMap()).toList(),
          'coupon_code': cart.appliedCoupon?.code,
          'payment_mode': _payment == PaymentChoice.upi ? 'upi' : 'cod',
          'delivery_address': selectedAddress.fullAddress,
          'address_label': selectedAddress.label,
          'latitude': selectedAddress.latitude,
          'longitude': selectedAddress.longitude,
        });

        orderId = result.data['order_id'] as String;
        _pendingOrderId = orderId;
        _pendingOrderSignature = signature;
      }

      // 2a. Cash on delivery: the order is already placed.
      if (_payment == PaymentChoice.cod) {
        _pendingOrderId = null;
        _pendingOrderSignature = null;
        cart.clear();
        if (!context.mounted) return;
        setState(() => _placing = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: orderId)),
        );
        return;
      }

      // 2b. Online / UPI payment via Razorpay
      final session =
      await functions.httpsCallable('razorpay_create_order').call({'order_id': orderId});

      final keyId = session.data['key_id'] as String;
      final amount = session.data['amount'] as int;
      final razorpayOrderId = session.data['razorpay_order_id'] as String;

      final options = RazorpayCheckoutOptions(
        keyId: keyId,
        amount: amount,
        razorpayOrderId: razorpayOrderId,
        appOrderId: orderId,
        contact: currentUser.phoneNumber ?? '',
        email: currentUser.email ?? '',
      );

      // _placing stays true while the Razorpay sheet is open so the Pay button
      // cannot be tapped twice; it is reset on every exit that stays on this screen.
      final paymentResult = await RazorpayPaymentService.openCheckout(options);

      if (!mounted || !context.mounted) return;

      if (!paymentResult.isSuccess) {
        setState(() => _placing = false);
        if (paymentResult.isDismissed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment cancelled')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(paymentResult.errorMessage ?? 'Payment failed'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Razorpay payment success! DO NOT clear cart here. Navigate immediately to PaymentConfirmationScreen.
      final confirmedOrderId = orderId;
      final rzpOrderId = paymentResult.razorpayOrderId ?? razorpayOrderId;
      final payId = paymentResult.paymentId ?? '';
      final sig = paymentResult.signature ?? '';

      _pendingOrderId = null;
      _pendingOrderSignature = null;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentConfirmationScreen(
            orderId: confirmedOrderId,
            razorpayOrderId: rzpOrderId,
            paymentId: payId,
            signature: sig,
          ),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint('FirebaseFunctionsException: code=${e.code}, message=${e.message}, details=${e.details}');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Server error during order placement.')),
      );
      setState(() => _placing = false);
    } catch (e) {
      debugPrint('Order placement error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start payment: $e')),
      );
      setState(() => _placing = false);
    }
  }
}