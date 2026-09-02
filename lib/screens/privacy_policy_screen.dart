import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for Maruthi Eats',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.maroon),
            ),
            12.verticalSpace,
            Text(
              'Last Updated: August 2026',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textDark.withValues(alpha: 0.5)),
            ),
            20.verticalSpace,
            _section('1. Information We Collect',
                'We collect information you provide directly to us, such as when you create an account, place an order, or contact customer support. This includes your name, phone number, delivery addresses, and order history.'),
            _section('2. How We Use Information',
                'We use the information we collect to process your orders, communicate with you about your account and promotions, and to improve our services and user experience.'),
            _section('3. Data Security',
                'We implement industry-standard security measures to protect your personal information. However, no method of transmission over the Internet is 100% secure.'),
            _section('4. Account Deletion',
                'You have the right to delete your account at any time through the app settings. Upon deletion, your personal data and order history will be removed from our active records.'),
            _section('5. Contact Us',
                'If you have any questions about this Privacy Policy, please contact us at support@maruthieats.com.'),
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
