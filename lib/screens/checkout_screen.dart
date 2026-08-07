import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../models/address_model.dart';
import 'saved_addresses_screen.dart';
import 'order_tracking_screen.dart';

enum PaymentChoice { upi, cod }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _authService = AuthService();
  AddressModel? _selectedAddress;
  PaymentChoice _payment = PaymentChoice.upi;
  bool _placing = false;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

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
                  child: Text(_selectedAddress == null ? 'Add Address' : 'Change',
                      style: TextStyle(color: AppColors.maroon, fontWeight: FontWeight.bold, fontSize: 13.sp)),
                ),
              ],
            ),
            8.verticalSpace,
            StreamBuilder<List<AddressModel>>(
              stream: _authService.watchAddresses(_authService.currentUser!.uid),
              builder: (context, snapshot) {
                final addresses = snapshot.data ?? [];
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.maroon));
                }

                if (addresses.isEmpty) {
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

                // If nothing selected yet, pick the first one
                if (_selectedAddress == null && addresses.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() => _selectedAddress = addresses.first);
                  });
                } else if (_selectedAddress != null) {
                  // Ensure current selection still exists in the latest list
                  final exists = addresses.any((a) => a.id == _selectedAddress!.id);
                  if (!exists) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _selectedAddress = addresses.first);
                    });
                  } else {
                    // Update selection with latest data (in case label changed)
                    final updated = addresses.firstWhere((a) => a.id == _selectedAddress!.id);
                    if (updated.fullAddress != _selectedAddress!.fullAddress || updated.label != _selectedAddress!.label) {
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() => _selectedAddress = updated);
                      });
                    }
                  }
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
                              Text(_selectedAddress?.label ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              4.verticalSpace,
                              Text(_selectedAddress?.fullAddress ?? '', 
                                  style: TextStyle(fontSize: 13.sp, color: AppColors.textDark.withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
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
                  Text('₹${cart.subtotal.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.maroon)),
                ],
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
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    setState(() => _placing = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'customer_id': userId,
        'items': cart.items.values.map((c) => c.toOrderMap()).toList(),
        'total': cart.subtotal,
        'payment_mode': _payment == PaymentChoice.upi ? 'upi' : 'cod',
        'payment_status': _payment == PaymentChoice.upi ? 'pending' : 'cod_pending',
        'order_status': 'placed',
        'delivery_address': _selectedAddress!.fullAddress,
        'address_label': _selectedAddress!.label,
        'latitude': _selectedAddress!.latitude,
        'longitude': _selectedAddress!.longitude,
        'created_at': FieldValue.serverTimestamp(),
      });

      // TODO: if _payment == PaymentChoice.upi, trigger the Razorpay/Cashfree
      // checkout flow here once the backend payment-session endpoint exists.

      cart.clear();

      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderRef.id)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not place order: $e')),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: selected ? AppColors.maroon.withValues(alpha: 0.06) : AppColors.white,
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
    );
  }
}
