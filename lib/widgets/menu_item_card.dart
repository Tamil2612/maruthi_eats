import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;

  const MenuItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.quantityOf(item.id);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.r),
                          decoration: BoxDecoration(
                            border: Border.all(color: item.isVeg ? AppColors.success : AppColors.error, width: 1.w),
                          ),
                          child: Icon(
                            Icons.circle,
                            size: 8.r,
                            color: item.isVeg ? AppColors.success : AppColors.error,
                          ),
                        ),
                        8.horizontalSpace,
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    6.verticalSpace,
                    Row(
                      children: [
                        Text(
                          '₹${item.effectivePrice.toStringAsFixed(0)}',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.maroon, fontSize: 14.sp),
                        ),
                        if (item.hasDiscount) ...[
                          8.horizontalSpace,
                          Text(
                            '₹${item.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: AppColors.textDark.withValues(alpha: 0.4),
                              fontSize: 12.sp,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    6.verticalSpace,
                    Text(
                      item.description,
                      style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.5), fontSize: 11.sp, height: 1.4.h),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              16.horizontalSpace,
              // Image & Add Button
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      width: 110.w,
                      height: 110.h,
                      color: AppColors.maroon.withValues(alpha: 0.05),
                      child: item.imageUrl.isNotEmpty
                          ? Image.network(item.imageUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.restaurant, color: AppColors.maroon, size: 32.r))
                          : Icon(Icons.restaurant, color: AppColors.maroon, size: 32.r),
                    ),
                  ),
                  Positioned(
                    bottom: -12.h,
                    child: item.available
                        ? (qty == 0
                            ? SizedBox(
                                width: 80.w,
                                height: 36.h,
                                child: ElevatedButton(
                                  onPressed: () => context.read<CartProvider>().addItem(item),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.white,
                                    foregroundColor: AppColors.maroon,
                                    side: BorderSide(color: AppColors.maroon.withValues(alpha: 0.2)),
                                    elevation: 2,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                  ),
                                  child: Text('ADD', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp)),
                                ),
                              )
                            : _QuantityStepper(item: item, qty: qty))
                        : Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text('SOLD OUT', style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w800, color: Colors.grey)),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final MenuItem item;
  final int qty;

  const _QuantityStepper({required this.item, required this.qty});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Container(
      width: 84.w,
      height: 36.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.maroon.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4.r, offset: Offset(0, 2.h)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => cart.removeOne(item.id),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Icon(Icons.remove, color: AppColors.maroon, size: 18.r),
            ),
          ),
          Text('$qty', style: TextStyle(color: AppColors.maroon, fontWeight: FontWeight.w800, fontSize: 14.sp)),
          InkWell(
            onTap: () => cart.addItem(item),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Icon(Icons.add, color: AppColors.maroon, size: 18.r),
            ),
          ),
        ],
      ),
    );
  }
}
