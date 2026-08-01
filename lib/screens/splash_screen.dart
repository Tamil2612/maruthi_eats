import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.maroon,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.maroon,
                border: Border.all(color: AppColors.gold, width: 2.w),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.restaurant_menu, color: AppColors.gold, size: 48.r),
            ),
            20.verticalSpace,
            Text('MARUTHI EATS', style: AppTheme.logoStyle),
            8.verticalSpace,
            Text(
              'Good food, delivered.',
              style: TextStyle(color: AppColors.gold.withValues(alpha: 0.8), fontSize: 13.sp, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
