import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'skeleton_loaders.dart';

class MenuItemDetailsSheet extends StatelessWidget {
  final MenuItem item;

  const MenuItemDetailsSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.quantityOf(item.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Indicator
          Container(
            margin: EdgeInsets.symmetric(vertical: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 40.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      width: double.infinity,
                      height: 160.h,
                      color: AppColors.maroon.withValues(alpha: 0.05),
                      child: item.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const ShimmerLoader(
                                child: SizedBox.expand(),
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
                  24.verticalSpace,

                  // Name & Veg/Non-Veg Tag
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 6.h),
                        padding: EdgeInsets.all(3.r),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: item.isVeg ? AppColors.success : AppColors.error,
                            width: 1.5.w,
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Icon(
                          Icons.circle,
                          size: 10.r,
                          color: item.isVeg ? AppColors.success : AppColors.error,
                        ),
                      ),
                      12.horizontalSpace,
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  8.verticalSpace,

                  // Category Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.maroon.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      item.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.maroon,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  10.verticalSpace,

                  // Price Section
                  Row(
                    children: [
                      Text(
                        '₹${item.effectivePrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.maroon,
                        ),
                      ),
                      if (item.hasDiscount) ...[
                        12.horizontalSpace,
                        Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark.withValues(alpha: 0.4),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        8.horizontalSpace,
                        Text(
                          '${(((item.price - item.discountPrice) / item.price) * 100).toStringAsFixed(0)}% OFF',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ],
                  ),
                  10.verticalSpace,
                  Text(
                    'Product Details',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  12.verticalSpace,
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textDark.withValues(alpha: 0.7),
                      height: 1.6,
                      letterSpacing: 0.3,
                    ),
                  ),
                  40.verticalSpace,

                  // Bottom Action Bar
                  Row(
                    children: [
                      Expanded(
                        child: item.available
                            ? (qty == 0
                                ? SizedBox(
                                    height: 46.h,
                                    child: OutlinedButton(
                                      onPressed: () => context.read<CartProvider>().addItem(item),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: AppColors.white,
                                        foregroundColor: AppColors.maroon,
                                        side: const BorderSide(color: AppColors.maroon, width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text(
                                        'ADD TO CART',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 46.h,
                                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.maroon,
                                      borderRadius: BorderRadius.circular(12.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.maroon.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          onPressed: () => cart.removeOne(item.id),
                                          icon: Icon(Icons.remove, color: AppColors.gold, size: 22.r),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        Text(
                                          '$qty',
                                          style: TextStyle(
                                            color: AppColors.gold,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18.sp,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => cart.addItem(item),
                                          icon: Icon(Icons.add, color: AppColors.gold, size: 22.r),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ))
                            : Container(
                                width: double.infinity,
                                height: 46.h,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  'OUT OF STOCK',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
