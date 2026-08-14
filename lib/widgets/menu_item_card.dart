import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'skeleton_loaders.dart';

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.r),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: item.isVeg
                                  ? AppColors.success
                                  : AppColors.error,
                              width: 1.w),
                        ),
                        child: Icon(
                          Icons.circle,
                          size: 6.r,
                          color:
                              item.isVeg ? AppColors.success : AppColors.error,
                        ),
                      ),
                      8.horizontalSpace,
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15.sp),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  8.verticalSpace,
                  Row(
                    children: [
                      Text(
                        '₹${item.effectivePrice.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.maroon,
                            fontSize: 14.sp),
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
                  8.verticalSpace,
                  Text(
                    item.description,
                    style: TextStyle(
                        color: AppColors.textDark.withValues(alpha: 0.5),
                        fontSize: 11.sp,
                        height: 1.4,
                        letterSpacing: 0.2),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            12.horizontalSpace,
            // Image & Add Button
            Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Container(
                    width: 100.w,
                    height: 100.h,
                    color: AppColors.maroon.withValues(alpha: 0.05),
                    child: item.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => ShimmerLoader(
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/icons/placeholder_food.png',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'assets/icons/placeholder_food.png',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  bottom: -12.h,
                  child: item.available
                      ? (qty == 0
                          ? SizedBox(
                              width: 76.w,
                              height: 32.h,
                              child: ElevatedButton(
                                onPressed: () =>
                                    context.read<CartProvider>().addItem(item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.white,
                                  foregroundColor: AppColors.maroon,
                                  side: BorderSide(
                                      color: AppColors.maroon
                                          .withValues(alpha: 0.2)),
                                  elevation: 2,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r)),
                                ),
                                child: Text('ADD',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.sp)),
                              ),
                            )
                          : _QuantityStepper(item: item, qty: qty))
                      : Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text('SOLD OUT',
                              style: TextStyle(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey)),
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
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4.r,
              offset: Offset(0, 2.h)),
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
          Text('$qty',
              style: TextStyle(
                  color: AppColors.maroon,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.sp)),
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
