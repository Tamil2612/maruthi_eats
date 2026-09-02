import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';

/// Shows a looping Lottie animation matching the current order status,
/// tinted to the brand maroon, sitting on a soft light-maroon backdrop,
/// with a status message below it — crossfades when the status changes.
///
/// SETUP:
/// 1. Add to pubspec.yaml:
///      dependencies:
///        lottie: ^3.1.2
///      flutter:
///        assets:
///          - assets/animations/
/// 2. Keep the .lottie extension as-is (it's a dotLottie zip bundle, not
///    plain JSON) — e.g. assets/animations/cooking.lottie
///    Save one file per status:
///      assets/animations/order_placed.lottie
///      assets/animations/order_confirmed.lottie
///      assets/animations/cooking.lottie
///      assets/animations/delivery.lottie
///      assets/animations/delivered.lottie
///
/// NOTE ON TINTING: ColorFiltered flattens the whole animation to one
/// color — great for line/icon-style loaders, but will look wrong on a
/// fully illustrated multi-color animation. If yours is illustrated,
/// set `tint: false` below and instead recolor it once in LottieFiles'
/// free online editor before exporting.
class OrderStatusAnimation extends StatelessWidget {
  final OrderStatus status;
  final bool tint;

  const OrderStatusAnimation({super.key, required this.status, this.tint = true});

  String get _assetPath {
    switch (status) {
      case OrderStatus.placed:
        return 'assets/animations/order_placed.json';
      case OrderStatus.preparing:
        return 'assets/animations/cooking.json';
      case OrderStatus.outForDelivery:
        return 'assets/animations/delivery.json';
      case OrderStatus.delivered:
        return 'assets/animations/delivered.json';
      case OrderStatus.cancelled:
        return 'assets/animations/order_placed.json';
    }
  }

  String get _statusText {
    switch (status) {
      case OrderStatus.placed:
        return 'Waiting for order confirmation...';
      case OrderStatus.preparing:
        return 'Your food is being prepared with care';
      case OrderStatus.outForDelivery:
        return 'Your order is on the way!';
      case OrderStatus.delivered:
        return 'Delivered — enjoy your meal!';
      case OrderStatus.cancelled:
        return '';
    }
  }

  IconData get _fallbackIcon {
    switch (status) {
      case OrderStatus.placed:
        return Icons.receipt_long_rounded;
      case OrderStatus.preparing:
        return Icons.soup_kitchen_rounded;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining_rounded;
      case OrderStatus.delivered:
        return Icons.home_rounded;
      case OrderStatus.cancelled:
        return Icons.close_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.maroon.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: Column(
          key: ValueKey(status), // forces AnimatedSwitcher to crossfade on status change
          mainAxisSize: MainAxisSize.min,
          children: [
            // Soft light-maroon circular backdrop behind the animation
            Container(
              width: 180.r,
              height: 180.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.maroon.withValues(alpha: 0.10),
                    AppColors.maroon.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(10.r),
                child: _buildAnimation(),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                _statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.maroon.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimation() {
    final lottie = Lottie.asset(
      _assetPath,
      fit: BoxFit.contain,
      repeat: true,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Icon(_fallbackIcon, size: 64.r, color: AppColors.maroon.withValues(alpha: 0.4)),
      ),
    );

    if (!tint) return lottie;

    // Tints the whole animation to brand maroon — best for line/icon-style
    // loaders. Set tint:false on this widget if your animation is a fully
    // illustrated multi-color piece instead.
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(AppColors.maroon, BlendMode.srcIn),
      child: lottie,
    );
  }
}