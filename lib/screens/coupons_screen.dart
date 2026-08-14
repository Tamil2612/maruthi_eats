import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/coupon.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Available Coupons')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('coupons').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading coupons'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.maroon));

          final coupons = snapshot.data!.docs
              .map((doc) => Coupon.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
              .where((c) => c.isActive && (c.expiryDate == null || c.expiryDate!.isAfter(DateTime.now())))
              .toList();

          if (coupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined, size: 64.r, color: AppColors.maroon.withValues(alpha: 0.2)),
                  16.verticalSpace,
                  const Text('No coupons available right now'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              final canApply = cart.subtotal >= coupon.minOrderValue;

              return Container(
                margin: EdgeInsets.only(bottom: 16.h),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: canApply ? AppColors.maroon.withValues(alpha: 0.1) : AppColors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: AppColors.maroon.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: AppColors.maroon.withValues(alpha: 0.1), style: BorderStyle.solid),
                          ),
                          child: Text(
                            coupon.code,
                            style: TextStyle(
                              color: AppColors.maroon,
                              fontWeight: FontWeight.w900,
                              fontSize: 14.sp,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: canApply
                              ? () {
                                  cart.applyCoupon(coupon);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Coupon "${coupon.code}" applied!')),
                                  );
                                }
                              : null,
                          child: Text(
                            'APPLY',
                            style: TextStyle(
                              color: canApply ? Colors.blue.shade800 : AppColors.grey,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    12.verticalSpace,
                    Text(
                      'Get ₹${coupon.amount.toStringAsFixed(0)} OFF',
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColors.maroon),
                    ),
                    4.verticalSpace,
                    Text(
                      coupon.rules,
                      style: TextStyle(fontSize: 12.sp, color: AppColors.textDark.withValues(alpha: 0.6)),
                    ),
                    if (!canApply) ...[
                      8.verticalSpace,
                      Text(
                        'Add ₹${(coupon.minOrderValue - cart.subtotal).toStringAsFixed(0)} more to apply this coupon',
                        style: TextStyle(color: AppColors.error, fontSize: 11.sp, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
