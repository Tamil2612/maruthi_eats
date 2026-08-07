import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: items.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12.h),
                        child: Padding(
                          padding: EdgeInsets.all(16.r),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Container(
                                  width: 50.w,
                                  height: 50.h,
                                  color: AppColors.maroon.withValues(alpha: 0.05),
                                  child: item.menuItem.imageUrl.isNotEmpty
                                      ? Image.network(item.menuItem.imageUrl, fit: BoxFit.cover)
                                      : Icon(Icons.restaurant, size: 20.r, color: AppColors.maroon),
                                ),
                              ),
                              16.horizontalSpace,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.menuItem.name,
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp)),
                                    2.verticalSpace,
                                    Text('₹${item.menuItem.price.toStringAsFixed(0)}',
                                        style: TextStyle(
                                            color: AppColors.textDark.withValues(alpha: 0.5),
                                            fontSize: 12.sp)),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.maroon.withValues(alpha: 0.1)),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove, size: 18.r, color: AppColors.maroon),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                                      onPressed: () =>
                                          context.read<CartProvider>().removeOne(item.menuItem.id),
                                    ),
                                    Text('${item.quantity}',
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp)),
                                    IconButton(
                                      icon: Icon(Icons.add, size: 18.r, color: AppColors.maroon),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                                      onPressed: () =>
                                          context.read<CartProvider>().addItem(item.menuItem),
                                    ),
                                  ],
                                ),
                              ),
                              16.horizontalSpace,
                              Text(
                                '₹${item.total.toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _CartSummary(cart: cart),
              ],
            ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartProvider cart;
  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text('Total Bill', style: TextStyle(fontSize: 13.sp, color: AppColors.textDark.withValues(alpha: 0.5))),
                Text('₹${cart.subtotal.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.maroon)),
              ],
            ),
            20.verticalSpace,
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.maroon,
                  foregroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: Text('Proceed to Checkout', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
