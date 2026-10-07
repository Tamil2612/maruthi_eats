import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/address_provider.dart';
import '../services/checkout_service.dart';
import '../theme/app_theme.dart';
import '../models/address_model.dart';
import '../models/cart_item.dart';
import 'saved_addresses_screen.dart';
import 'order_success_screen.dart';

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
  late final Razorpay _razorpay;

  String? _pendingOrderId;
  PaymentChoice? _pendingOrderChoice;

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
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final addressProvider = context.watch<AddressProvider>();
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
            _buildPaymentOption(
              title: 'Pay via UPI',
              subtitle: 'GPay, PhonePe, Paytm, BHIM & more',
              badge: 'RECOMMENDED',
              icon: Icons.qr_code_scanner_rounded,
              selected: _payment == PaymentChoice.upi,
              onTap: () => setState(() => _payment = PaymentChoice.upi),
            ),
            10.verticalSpace,
            _buildPaymentOption(
              title: 'Cash on Delivery',
              subtitle: 'Pay cash or UPI upon delivery',
              badge: null,
              icon: Icons.payments_outlined,
              selected: _payment == PaymentChoice.cod,
              onTap: () => setState(() => _payment = PaymentChoice.cod),
            ),
            20.verticalSpace,

            // 4. Bill Details Summary Card
            _buildSectionHeader(
              icon: Icons.receipt_long_outlined,
              title: 'Bill Details',
            ),
            8.verticalSpace,
            _buildBillDetailsCard(cart),
            20.verticalSpace,

            // 5. Safety & Trust Note
            _buildSafetyNote(),
            32.verticalSpace,
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
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: AppColors.maroon.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18.r, color: AppColors.maroon),
            ),
            10.horizontalSpace,
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
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
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.03),
              blurRadius: 10.r,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off_outlined, color: AppColors.error),
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Address Selected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
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
                6.verticalSpace,
                Text(
                  selectedAddress.fullAddress,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
                if (selectedAddress.recipientName.isNotEmpty ||
                    selectedAddress.recipientPhone.isNotEmpty) ...[
                  8.verticalSpace,
                  Text(
                    '${selectedAddress.recipientName} • ${selectedAddress.recipientPhone}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey,
                    ),
                  ),
                ]
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
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.maroon.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 10.r,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              height: 16.h,
              color: AppColors.textDark.withValues(alpha: 0.05),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildOrderItemRow(item);
            },
          ),
          if (cart.appliedCoupon != null) ...[
            12.verticalSpace,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer_outlined, color: AppColors.success, size: 16.r),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(
                      'Coupon "${cart.appliedCoupon!.code}" applied! Saved ₹${cart.couponDiscount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(CartItem item) {
    return Row(
      children: [
        // Veg / Non-Veg dot icon
        Container(
          width: 14.r,
          height: 14.r,
          padding: EdgeInsets.all(2.r),
          decoration: BoxDecoration(
            border: Border.all(
              color: item.isVeg ? AppColors.success : AppColors.error,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(3.r),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: item.isVeg ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
        ),
        10.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.offerDescription != null)
                Text(
                  item.offerDescription!,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.maroon,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        Text(
          'x${item.quantity}',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.grey,
          ),
        ),
        16.horizontalSpace,
        Text(
          item.isFree ? 'FREE' : '₹${item.total.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
            color: item.isFree ? AppColors.success : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required String? badge,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: selected ? AppColors.maroon.withValues(alpha: 0.05) : AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? AppColors.maroon : AppColors.grey.withValues(alpha: 0.2),
            width: selected ? 2.w : 1.w,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: AppColors.maroon.withValues(alpha: 0.08),
                blurRadius: 12.r,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.02),
                blurRadius: 6.r,
                offset: const Offset(0, 2),
              )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: selected ? AppColors.maroon : AppColors.maroon.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.gold : AppColors.maroon,
                size: 22.r,
              ),
            ),
            14.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (badge != null) ...[
                        8.horizontalSpace,
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                  4.verticalSpace,
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textDark.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20.r,
              height: 20.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.maroon : AppColors.grey,
                  width: selected ? 6.r : 1.5.r,
                ),
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillDetailsCard(CartProvider cart) {
    final double minOrderValue = cart.minimumOrderValue;
    final bool meetsMinOrder = cart.subtotal >= minOrderValue;
    final double shortfall = meetsMinOrder ? 0.0 : (minOrderValue - cart.subtotal);
    final double? distanceKm = _previewData != null ? (_previewData!['distance_km'] ?? 0.0).toDouble() : null;
    final bool isDeliverable = _previewData?['is_deliverable'] ?? true;
    final String deliveryMsg = _previewData?['delivery_message'] ?? 'Outside delivery area';
    final bool isAvailable = _previewData?['is_available'] ?? true;
    final String statusMsg = _previewData?['status_message'] ?? 'Restaurant is currently unavailable';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.maroon.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 10.r,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _billRow('Item Total', cart.subtotal),
          if (cart.couponDiscount > 0) ...[
            6.verticalSpace,
            _billRow('Coupon Discount', -cart.couponDiscount, isDiscount: true),
          ],
          if (distanceKm != null && distanceKm > 0) ...[
            6.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Distance',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '${distanceKm.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isDeliverable ? AppColors.textDark : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
          6.verticalSpace,
          _billRow(
            'Delivery Fee',
            cart.deliveryFee,
            isFreeDelivery: cart.deliveryFee == 0,
          ),
          if (cart.previewFailed) ...[
            4.verticalSpace,
            Text(
              'Delivery fee calculated at payment',
              style: TextStyle(fontSize: 11.sp, color: AppColors.grey, fontStyle: FontStyle.italic),
            ),
          ],
          6.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Minimum Order',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textDark.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '₹${minOrderValue.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: meetsMinOrder ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          if (!isAvailable) ...[
            10.verticalSpace,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.storefront_outlined, color: AppColors.error, size: 16.r),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(
                      statusMsg,
                      style: TextStyle(color: AppColors.error, fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!isDeliverable) ...[
            10.verticalSpace,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_off_outlined, color: AppColors.error, size: 16.r),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(
                      deliveryMsg,
                      style: TextStyle(color: AppColors.error, fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!meetsMinOrder) ...[
            10.verticalSpace,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.error, size: 16.r),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(
                      'Add ₹${shortfall.toStringAsFixed(0)} more to place your order.',
                      style: TextStyle(color: AppColors.error, fontSize: 12.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!isDeliverable) ...[
            10.verticalSpace,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_off_outlined, color: AppColors.error, size: 16.r),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(
                      deliveryMsg,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!meetsMinOrder) ...[
            10.verticalSpace,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.error, size: 16.r),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(
                      'Add ₹${shortfall.toStringAsFixed(0)} more to place your order.',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          8.verticalSpace,
          Divider(color: AppColors.textDark.withValues(alpha: 0.08)),
          8.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '₹${cart.totalPayable.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.maroon,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(
    String label,
    double amount, {
    bool isDiscount = false,
    bool isFreeDelivery = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: isDiscount ? AppColors.success : AppColors.textDark.withValues(alpha: 0.7),
            fontWeight: isDiscount ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          isFreeDelivery
              ? 'FREE'
              : '${amount < 0 ? "-" : ""}₹${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isDiscount || isFreeDelivery ? AppColors.success : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyNote() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.maroon.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: ColorScheme.fromSeed(seedColor: AppColors.maroon).brightness ==
                Brightness.light
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.maroon, size: 18.r),
          8.horizontalSpace,
          Expanded(
            child: Text(
              '100% Safe Payments • Quality Assured Food',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.maroon,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPayBar(CartProvider cart) {
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
                  onPressed: (_placing || !canPlace) ? null : () => _placeOrder(context, cart),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.maroon,
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
                              _payment == PaymentChoice.upi ? 'Pay via UPI' : 'Place Order',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                              ),
                            ),
                            6.horizontalSpace,
                            Icon(
                              _payment == PaymentChoice.upi
                                  ? Icons.arrow_forward_rounded
                                  : Icons.check_circle_outline,
                              size: 18.r,
                              color: AppColors.gold,
                            ),
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

    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    setState(() => _placing = true);

    try {
      final functions = FirebaseFunctions.instanceFor(region: _functionsRegion);

      // 1. Create the order on the server (priced server-side).
      String orderId;
      if (_pendingOrderId != null && _pendingOrderChoice == _payment) {
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

        final serverTotal = (result.data['total'] as num).toDouble();
        final shownTotal = cart.totalPayable;

        // Safety net: compare server total with displayed total
        if ((serverTotal - shownTotal).abs() > 0.50) {
          if (!context.mounted) return;
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Order Total Updated'),
              content: Text(
                'The final order total from the server is ₹${serverTotal.toStringAsFixed(0)} '
                '(Delivery Fee: ₹${((result.data['delivery_fee'] ?? cart.deliveryFee) as num).toStringAsFixed(0)}).\n\n'
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

        orderId = result.data['order_id'] as String;
        _pendingOrderId = orderId;
        _pendingOrderChoice = _payment;
      }

      // 2a. Cash on delivery: the order is already placed.
      if (_payment == PaymentChoice.cod) {
        _pendingOrderId = null;
        _pendingOrderChoice = null;
        cart.clear();
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: orderId)),
        );
        return;
      }

      // 2b. UPI: the order stays "pending_payment" (invisible to the
      // restaurant) until the server verifies the payment. Nothing is
      // deleted on failure - the server expires unpaid orders by itself.
      final user = FirebaseAuth.instance.currentUser;
      final session =
          await functions.httpsCallable('razorpay_create_order').call({'order_id': orderId});

      final keyId = session.data['key_id'] as String;
      final amount = session.data['amount'] as int;
      final razorpayOrderId = session.data['razorpay_order_id'] as String;

      _razorpay.open({
        'key': keyId,
        'amount': amount,
        'order_id': razorpayOrderId,
        'currency': 'INR',
        'name': 'Maruthi Eats',
        'description': 'Order #${orderId.substring(0, 6).toUpperCase()}',
        'prefill': {
          'contact': user?.phoneNumber ?? '',
          'email': user?.email ?? '',
        },
        'timeout': 600, // seconds the customer has to finish paying
      });
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

  /// Razorpay says the payment went through. The app can NOT mark the order
  /// paid itself (Firestore rules forbid it, and it would be unsafe): the
  /// server checks Razorpay's signature and only then places the order.
  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final orderId = _pendingOrderId;
    if (orderId == null) {
      if (mounted) setState(() => _placing = false);
      return;
    }

    String? status;
    try {
      final result = await FirebaseFunctions.instanceFor(region: _functionsRegion)
          .httpsCallable('razorpay_verify_payment')
          .call({
        'order_id': orderId,
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });
      status = result.data['status'] as String?;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('razorpay_verify_payment failed: code=${e.code}, message=${e.message}');
      if (e.code == 'permission-denied' || e.code == 'invalid-argument') {
        if (mounted) {
          setState(() => _placing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Could not verify the payment.')),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('razorpay_verify_payment error: $e');
    }

    final paid = status == 'paid' || status == 'already_paid' || await _waitUntilPaid(orderId);
    if (!mounted) return;
    setState(() => _placing = false);

    if (status == 'needs_refund') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your payment arrived after the order timed out. '
              'It will be refunded - please place the order again.'),
        ),
      );
      return;
    }

    _pendingOrderId = null;
    _pendingOrderChoice = null;
    context.read<CartProvider>().clear();
    if (!paid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment received. We are confirming your order - '
              'it will appear in Your Orders in a moment.'),
        ),
      );
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: orderId)),
    );
  }

  /// Waits (max 20 s) for the server/webhook to flip the order to paid.
  Future<bool> _waitUntilPaid(String orderId, {int timeoutSeconds = 20}) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .snapshots()
          .firstWhere((s) => s.data()?['payment_status'] == 'paid')
          .timeout(Duration(seconds: timeoutSeconds));
      return true;
    } catch (_) {
      return false;
    }
  }

  void _onPaymentError(PaymentFailureResponse response) async {
    final orderId = _pendingOrderId;

    // Check once more (short 3s wait) if the webhook or server confirmed payment in the background
    if (orderId != null) {
      final paid = await _waitUntilPaid(orderId, timeoutSeconds: 3);
      if (paid && mounted) {
        _pendingOrderId = null;
        _pendingOrderChoice = null;
        setState(() => _placing = false);
        context.read<CartProvider>().clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: orderId)),
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() => _placing = false);
    final cancelled = response.code == Razorpay.PAYMENT_CANCELLED;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(cancelled
            ? 'Payment cancelled. You can try again.'
            : 'Payment failed: ${response.message ?? 'Please try again.'}'),
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (mounted) setState(() => _placing = false);
  }
}
