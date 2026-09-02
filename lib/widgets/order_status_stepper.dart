import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

class OrderStatusStepper extends StatelessWidget {
  final OrderStatus currentStatus;

  const OrderStatusStepper({super.key, required this.currentStatus});

  static const _steps = [
    OrderStatus.placed,
    OrderStatus.preparing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  static const _icons = [
    Icons.receipt_long,
    Icons.soup_kitchen,
    Icons.delivery_dining,
    Icons.home,
  ];

  @override
  Widget build(BuildContext context) {
    if (currentStatus == OrderStatus.cancelled) {
      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: AppColors.error, size: 24.r),
            12.horizontalSpace,
            Text('This order was cancelled', style: TextStyle(color: AppColors.error, fontSize: 14.sp)),
          ],
        ),
      );
    }

    final currentIndex = _steps.indexOf(currentStatus);

    return Column(
      children: List.generate(_steps.length, (i) {
        final isDone = i <= currentIndex;
        final isLast = i == _steps.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.maroon : AppColors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _icons[i],
                      size: 16.r,
                      color: isDone ? AppColors.gold : AppColors.grey,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2.w,
                        color: isDone ? AppColors.maroon : AppColors.grey.withValues(alpha: 0.1),
                      ),
                    ),
                ],
              ),
              12.horizontalSpace,
              Padding(
                padding: EdgeInsets.only(bottom: 24.h, top: 6.h),
                child: Text(
                  orderStatusLabel(_steps[i]),
                  style: TextStyle(
                    fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                    color: isDone ? AppColors.textDark : AppColors.grey,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
