import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Conditions',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.maroon),
            ),
            12.verticalSpace,
            Text(
              'Last Updated: August 2026',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textDark.withValues(alpha: 0.5)),
            ),
            20.verticalSpace,
            _section('1. Acceptance of Terms',
                'By using the Maruthi Eats application, you agree to comply with and be bound by these Terms and Conditions.'),
            _section('2. Account Responsibility',
                'You are responsible for maintaining the confidentiality of your account and for all activities that occur under your account.'),
            _section('3. Ordering and Payment',
                'All orders placed through the app are subject to acceptance by the restaurant. Prices and availability are subject to change without notice.'),
            _section('4. Limitation of Liability',
                'Maruthi Eats shall not be liable for any indirect, incidental, or consequential damages resulting from the use or inability to use our services.'),
            _section('5. Modifications',
                'We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of the new terms.'),
            40.verticalSpace,
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          8.verticalSpace,
          Text(content, style: TextStyle(fontSize: 13.sp, color: AppColors.textDark.withValues(alpha: 0.7), height: 1.5)),
        ],
      ),
    );
  }
}
