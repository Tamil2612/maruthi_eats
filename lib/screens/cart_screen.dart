import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/address_provider.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../models/address_model.dart';
import 'checkout_screen.dart';
import 'full_menu_screen.dart';
import 'coupons_screen.dart';
import 'saved_addresses_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        centerTitle: false,
      ),
      body: items.isEmpty
          ? _buildEmptyState(context)
          : Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              children: [
                // Delivery Address Shortcut
                const _DeliveryAddressCard(),
                24.verticalSpace,

                // Cart Items
                ...items.map((item) => _CartItemRow(item: item)),

                // Add More Items Button
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FullMenuScreen()),
                  ),
                  icon: Icon(Icons.add_circle_outline, size: 20.r, color: AppColors.maroon),
                  label: Text(
                    'Add more items',
                    style: TextStyle(
                      color: AppColors.maroon,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                ),

                const Divider(),
                24.verticalSpace,

                // Coupon Section
                const _CouponSection(),
                24.verticalSpace,
                const Divider(thickness: 1),
                24.verticalSpace,

                // Bill Details Section
                _BillDetails(cart: cart),

                32.verticalSpace,

                // Cancellation Policy
                _CancellationPolicy(),

                100.verticalSpace,
              ],
            ),
          ),
          _StickyCheckoutBar(cart: cart),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64.r, color: AppColors.maroon.withValues(alpha: 0.2)),
          16.verticalSpace,
          Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.textDark.withValues(alpha: 0.6)),
          ),
          24.verticalSpace,
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go to Menu'),
          ),
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final dynamic item; // CartItem
  const _CartItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isLinkedBogo = item.parentOfferId != null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Details (Name + Tag)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.textDark, fontFamily: 'Poppins'),
                    children: [
                      TextSpan(text: item.name),
                      const WidgetSpan(child: SizedBox(width: 8)),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: item.isOffer 
                          ? Icon(item.isFree ? Icons.card_giftcard : Icons.stars, 
                              size: 14.r, 
                              color: item.isFree ? AppColors.success : AppColors.gold)
                          : Container(
                              padding: EdgeInsets.all(2.r),
                              decoration: BoxDecoration(
                                border: Border.all(color: item.isVeg ? AppColors.success : AppColors.error, width: 1.w),
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                              child: Icon(
                                Icons.circle,
                                size: 6.r,
                                color: item.isVeg ? AppColors.success : AppColors.error,
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
                if (item.offerDescription != null) ...[
                  2.verticalSpace,
                  Text(
                    item.offerDescription!,
                    style: TextStyle(fontSize: 11.sp, color: AppColors.textDark.withValues(alpha: 0.5), height: 1.2),
                  ),
                ],
              ],
            ),
          ),

          // Stepper & Pricing
          12.horizontalSpace,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!item.isFree) // Free items don't have their own stepper
                Container(
                  height: 30.h,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.maroon.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          final couponDropped = context.read<CartProvider>().removeOne(item.id);
                          if (couponDropped) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Coupon removed as your order no longer meets its minimum value')),
                            );
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Icon(Icons.remove, size: 14.r, color: AppColors.maroon),
                        ),
                      ),
                      Text(
                        '${item.quantity}',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.maroon),
                      ),
                      InkWell(
                        onTap: () => context.read<CartProvider>().incrementItem(item.id),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Icon(Icons.add, size: 14.r, color: AppColors.maroon),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'LINKED DEAL',
                  style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w800, color: AppColors.success.withValues(alpha: 0.6)),
                ),

              8.verticalSpace,
              // Individual Price with Discount logic
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.isFree && item.originalPrice != null) ...[
                    Text(
                      '₹${item.originalPrice!.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textDark.withValues(alpha: 0.4),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    4.horizontalSpace,
                    Text(
                      'FREE',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ] else ...[
                    if (!item.isOffer && item.menuItem?.hasDiscount == true) ...[
                      Text(
                        '₹${item.menuItem!.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textDark.withValues(alpha: 0.4),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      4.horizontalSpace,
                    ],
                    Text(
                      '₹${item.unitPrice.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.maroon),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CouponSection extends StatelessWidget {
  const _CouponSection();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final coupon = cart.appliedCoupon;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CouponsScreen()),
      ),
      child: Row(
        children: [
          Icon(
            coupon != null ? Icons.check_circle : Icons.local_offer_outlined,
            color: coupon != null ? AppColors.success : AppColors.maroon,
            size: 24.r,
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon != null ? 'Coupon "${coupon.code}" applied' : 'Apply Coupon',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
                Text(
                  coupon != null ? 'You saved ₹${cart.couponDiscount.toStringAsFixed(0)}' : 'Save more with available offers',
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: coupon != null ? AppColors.success : AppColors.textDark.withValues(alpha: 0.5)
                  ),
                ),
              ],
            ),
          ),
          if (coupon != null)
            TextButton(
              onPressed: () => cart.removeCoupon(),
              child: Text(
                'REMOVE',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800, fontSize: 12.sp),
              ),
            )
          else
            Icon(Icons.arrow_forward_ios_rounded, size: 14.r, color: AppColors.textDark.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}

class _BillDetails extends StatelessWidget {
  final CartProvider cart;
  const _BillDetails({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bill Details',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
        ),
        16.verticalSpace,
        _billRow('Item Total', cart.subtotal),
        if (cart.couponDiscount > 0)
          _billRow('Coupon Discount', -cart.couponDiscount, isDiscount: true),
        _billRow('Delivery Partner Fee', cart.deliveryFee, isInfo: true),
        12.verticalSpace,
        const Divider(thickness: 1.5),
        12.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'To Pay',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900),
            ),
            Text(
              '₹${cart.totalPayable.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: AppColors.maroon),
            ),
          ],
        ),
      ],
    );
  }

  Widget _billRow(String label, double amount, {bool isInfo = false, bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDiscount ? AppColors.success : AppColors.textDark.withValues(alpha: 0.6),
                ),
              ),
              if (isInfo) ...[
                4.horizontalSpace,
                Icon(Icons.info_outline, size: 12.r, color: AppColors.textDark.withValues(alpha: 0.4)),
              ],
            ],
          ),
          Text(
            '${amount < 0 ? "-" : ""}₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12.sp,
              color: isDiscount ? AppColors.success : AppColors.textDark.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancellationPolicy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.textDark.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review your order and address details to avoid cancellations',
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.textDark.withValues(alpha: 0.8)),
          ),
          8.verticalSpace,
          Text(
            'Note: If you cancel after the order is being prepared, a 100% cancellation fee will be applied.',
            style: TextStyle(fontSize: 10.sp, color: AppColors.textDark.withValues(alpha: 0.4), height: 1.4),
          ),
          8.verticalSpace,
          Text(
            'Read cancellation policy',
            style: TextStyle(fontSize: 10.sp, color: AppColors.error, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
          ),
        ],
      ),
    );
  }
}

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard();

  @override
  Widget build(BuildContext context) {
    final addressProvider = context.watch<AddressProvider>();
    final address = addressProvider.selectedAddress;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
      ),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.maroon.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.maroon.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on, color: AppColors.maroon, size: 20.r),
            ),
            16.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address != null ? 'Delivering to ${address.label}' : 'Set Delivery Address',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
                      ),
                      4.horizontalSpace,
                      Icon(Icons.keyboard_arrow_down, size: 16.r, color: AppColors.textDark.withValues(alpha: 0.5)),
                    ],
                  ),
                  Text(
                    address?.fullAddress ?? 'Add or select an address to proceed',
                    style: TextStyle(fontSize: 11.sp, color: AppColors.textDark.withValues(alpha: 0.5)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyCheckoutBar extends StatelessWidget {
  final CartProvider cart;
  const _StickyCheckoutBar({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5)),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${cart.totalPayable.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: AppColors.maroon),
                ),
                Text(
                  'VIEW DETAILED BILL',
                  style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold, color: AppColors.gold, letterSpacing: 0.5),
                ),
              ],
            ),
            12.horizontalSpace,
            Expanded(
              child: SizedBox(
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.maroon,
                    foregroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Proceed to Checkout',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
                        ),
                        4.horizontalSpace,
                        Icon(Icons.arrow_forward_ios_rounded, size: 12.r),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}