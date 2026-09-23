import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/address_provider.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/address_model.dart';
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

  // Set once place_order succeeds. If a later step (opening the Razorpay
  // session) fails and the user retries, we reuse this instead of calling
  // place_order again — otherwise a network hiccup between order creation
  // and payment would create a duplicate order on every retry.
  String? _pendingOrderId;

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
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final selectedAddress = addressProvider.selectedAddress;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
                  ),
                  child: Text(selectedAddress == null ? 'Add Address' : 'Change',
                      style: TextStyle(color: AppColors.maroon, fontWeight: FontWeight.bold, fontSize: 13.sp)),
                ),
              ],
            ),
            8.verticalSpace,
            _buildAddressSection(context, selectedAddress, addressProvider.addresses),
            24.verticalSpace,
            Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
            8.verticalSpace,
            _PaymentOption(
              title: 'Pay via UPI',
              subtitle: 'GPay, PhonePe, Paytm & more',
              icon: Icons.qr_code_scanner,
              selected: _payment == PaymentChoice.upi,
              onTap: () => setState(() => _payment = PaymentChoice.upi),
            ),
            10.verticalSpace,
            _PaymentOption(
              title: 'Cash on Delivery',
              subtitle: 'Pay when your order arrives',
              icon: Icons.payments_outlined,
              selected: _payment == PaymentChoice.cod,
              onTap: () => setState(() => _payment = PaymentChoice.cod),
            ),
            24.verticalSpace,
            const Divider(),
            16.verticalSpace,
            _CheckoutBillDetails(cart: cart),
            40.verticalSpace,
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          boxShadow: [
            BoxShadow(color: AppColors.black.withValues(alpha: 0.08), blurRadius: 20.r, offset: Offset(0, -10.h)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Payable', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                  Text('₹${cart.totalPayable.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.maroon)),
                ],
              ),
              if (cart.couponDiscount > 0)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    'Savings of ₹${cart.couponDiscount.toStringAsFixed(0)} applied!',
                    style: TextStyle(fontSize: 11.sp, color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ),
              20.verticalSpace,
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _placing ? null : () => _placeOrder(context, cart),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.maroon,
                    foregroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  child: _placing
                      ? SizedBox(
                      height: 20.h, width: 20.w,
                      child: CircularProgressIndicator(strokeWidth: 2.w, color: AppColors.gold))
                      : Text(_payment == PaymentChoice.upi ? 'Pay & Place Order' : 'Place Order'),
                ),
              ),
            ],
          ),
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
      String orderId;
      if (_pendingOrderId != null) {
        // Reuse the order from a previous attempt — see field comment.
        orderId = _pendingOrderId!;
      } else {
        final result = await FirebaseFunctions.instanceFor(region: _functionsRegion)
            .httpsCallable('place_order')
            .call({
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
      }

      if (_payment == PaymentChoice.cod) {
        _pendingOrderId = null;
        cart.clear();
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: orderId)),
        );
        return;
      }

      // UPI: open a Razorpay checkout session for the order just created.
      // Cart is only cleared and _placing reset once a payment result
      // comes back — see _onPaymentSuccess/_onPaymentError below — since
      // we're now waiting on the user inside the Razorpay UI, not on
      // anything awaited here.
      final session = await FirebaseFunctions.instanceFor(region: _functionsRegion)
          .httpsCallable('razorpay_create_order')
          .call({'order_id': orderId});

      _razorpay.open({
        'key': session.data['key_id'],
        'amount': session.data['amount'],
        'order_id': session.data['razorpay_order_id'],
        'name': 'Maruthi Eats',
        'description': 'Order #${orderId.substring(0, 6).toUpperCase()}',
      });
    } on FirebaseFunctionsException catch (e) {
      // e.message carries the specific reason the backend rejected the
      // order (e.g. "Coupon has expired", "Item no longer available")
      // instead of a raw exception string.
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not place order. Please try again.')),
      );
      setState(() => _placing = false);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not place order: $e')),
      );
      setState(() => _placing = false);
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    // This confirms the Razorpay checkout UI reported success — the
    // authoritative payment_status update still comes from
    // razorpay_webhook (signature-verified server-side), not from here.
    final orderId = _pendingOrderId;
    _pendingOrderId = null;
    if (mounted) setState(() => _placing = false);
    if (orderId == null || !mounted) return;

    context.read<CartProvider>().clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: orderId)),
    );
  }

  void _onPaymentError(PaymentFailureResponse response) {
    // The order document itself is left as-is (payment_status stays
    // 'pending' unless razorpay_webhook has already marked it 'failed').
    // _pendingOrderId is kept so retrying reuses the same order instead
    // of creating a duplicate.
    if (mounted) setState(() => _placing = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message ?? 'Please try again.'}')),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (mounted) setState(() => _placing = false);
  }

  Widget _buildAddressSection(BuildContext context, AddressModel? selectedAddress, List<AddressModel> allAddresses) {
    if (allAddresses.isEmpty) {
      return InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
        ),
        child: Container(
          padding: EdgeInsets.all(16.r),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_off_outlined, color: AppColors.error),
              12.horizontalSpace,
              const Text('No address saved. Tap to add one.', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      );
    }

    if (selectedAddress == null) {
      return const Center(child: Text('Please select an address'));
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: AppColors.maroon),
            16.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selectedAddress.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  4.verticalSpace,
                  Text(selectedAddress.fullAddress,
                      style: TextStyle(fontSize: 13.sp, color: AppColors.textDark.withValues(alpha: 0.6))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutBillDetails extends StatelessWidget {
  final CartProvider cart;
  const _CheckoutBillDetails({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bill Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp)),
        12.verticalSpace,
        _billRow('Item Total', cart.subtotal),
        if (cart.couponDiscount > 0)
          _billRow('Coupon Discount', -cart.couponDiscount, isDiscount: true),
        _billRow('Delivery Fee', cart.deliveryFee),
      ],
    );
  }

  Widget _billRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 13.sp,
                color: isDiscount ? AppColors.success : AppColors.textDark.withValues(alpha: 0.6)
            ),
          ),
          Text(
            '${amount < 0 ? "-" : ""}₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 13.sp,
                color: isDiscount ? AppColors.success : AppColors.textDark.withValues(alpha: 0.8)
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.maroon.withValues(alpha: 0.06)
                : AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected ? AppColors.maroon : AppColors.grey.withValues(alpha: 0.3),
              width: selected ? 1.5.w : 1.w,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.maroon, size: 24.r),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12.sp, color: AppColors.textDark.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.maroon : AppColors.grey,
                size: 20.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}