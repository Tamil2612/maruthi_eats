import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'skeleton_loaders.dart';
import 'menu_item_details_sheet.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;

  const MenuItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.quantityOf(item.id);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.maroon.withValues(alpha: 0.05), width: 1.w),
      ),
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => MenuItemDetailsSheet(item: item),
        ),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side: Text Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 4.h),
                          padding: EdgeInsets.all(1.5.r),
                          decoration: BoxDecoration(
                            border: Border.all(color: item.isVeg ? AppColors.success : AppColors.error, width: 1.w),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                          child: Icon(Icons.circle, size: 6.r, color: item.isVeg ? AppColors.success : AppColors.error),
                        ),
                        8.horizontalSpace,
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark.withValues(alpha: 0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    4.verticalSpace,
                    // Price
                    Row(
                      children: [
                        Text(
                          '₹${item.effectivePrice.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.maroon),
                        ),
                        if (item.hasDiscount) ...[
                          8.horizontalSpace,
                          Text(
                            '₹${item.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textDark.withValues(alpha: 0.4),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    12.verticalSpace,
                    // Description
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textDark.withValues(alpha: 0.5),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              12.horizontalSpace,
              // Right Side: Image & Add Button
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      width: 110.w,
                      height: 95.h,
                      color: AppColors.maroon.withValues(alpha: 0.05),
                      child: item.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const ShimmerLoader(child: SizedBox.expand()),
                              errorWidget: (context, url, error) => Image.asset('assets/icons/placeholder_food.png', fit: BoxFit.cover),
                            )
                          : Image.asset('assets/icons/placeholder_food.png', fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    bottom: -12.h,
                    child: item.available
                        ? (qty == 0 ? _AddButton(item: item) : _QuantityStepper(item: item, qty: qty))
                        : _SoldOutBadge(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final MenuItem item;
  const _AddButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.maroon.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextButton(
        onPressed: () => context.read<CartProvider>().addItem(item),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Text(
          'ADD',
          style: TextStyle(color: AppColors.maroon, fontWeight: FontWeight.w900, fontSize: 13.sp),
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
      width: 90.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: AppColors.maroon,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(color: AppColors.maroon.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => cart.removeOne(item.id),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(8.r)),
              child: Center(
                child: Icon(Icons.remove, color: AppColors.gold, size: 16.r),
              ),
            ),
          ),
          Text(
            '$qty',
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 13.sp),
          ),
          Expanded(
            child: InkWell(
              onTap: () => cart.addItem(item),
              borderRadius: BorderRadius.horizontal(right: Radius.circular(8.r)),
              child: Center(
                child: Icon(Icons.add, color: AppColors.gold, size: 16.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoldOutBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColors.maroon.withValues(alpha: 0.1)),
      ),
      child: Text(
        'SOLD OUT',
        style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w900, color: AppColors.maroon.withValues(alpha: 0.4)),
      ),
    );
  }
}
