import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../screens/cart_screen.dart';

class CartFab extends StatelessWidget {
  final double bottom;

  const CartFab({super.key, required this.bottom});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.itemCount == 0) return const SizedBox.shrink();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      bottom: bottom,
      right: 16.w,
      child: Badge(
        label: Text(cart.itemCount.toString(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.sp)),
        backgroundColor: AppColors.gold,
        textColor: AppColors.maroon,
        largeSize: 20.r,
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: FloatingActionButton(
          tooltip: 'Open cart (${cart.itemCount} items)',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
          backgroundColor: AppColors.maroon,
          shape: const CircleBorder(),
          // child: const Icon(Icons.shopping_bag_outlined, color: AppColors.gold),
          child: Image.asset(
            "assets/icons/cart.png",
            color: AppColors.gold,
            height: 32.h,
            width: 32.w,
          ),
        ),
      ),
    );
  }
}
