import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.r),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: AppColors.maroon,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2.w),
                  ),
                  child: Icon(Icons.restaurant_menu,
                      color: AppColors.gold, size: 40.r),
                ),
                24.verticalSpace,
                Text('MARUTHI EATS',
                    style: AppTheme.logoStyle
                        .copyWith(color: AppColors.maroon, fontSize: 32.sp)),
                8.verticalSpace,
                Text(
                  'Authentic flavors, delivered to your door.',
                  style: TextStyle(
                      color: AppColors.textDark.withValues(alpha: 0.6),
                      fontSize: 14.sp),
                ),
                40.verticalSpace,
                Card(
                  elevation: 4,
                  shadowColor: AppColors.maroon.withValues(alpha: 0.1),
                  child: Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Login or Sign up',
                          style: TextStyle(
                              fontSize: 18.sp, fontWeight: FontWeight.w700),
                        ),
                        4.verticalSpace,
                        Text(
                          'Enter your mobile number to continue',
                          style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.textDark.withValues(alpha: 0.6)),
                        ),
                        24.verticalSpace,
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.cream.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                                color: AppColors.maroon.withValues(alpha: 0.1)),
                          ),
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            textAlignVertical: TextAlignVertical.center,
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2.w),
                            decoration: InputDecoration(
                              prefixIcon: Padding(
                                padding:
                                    EdgeInsets.only(left: 12.w, right: 4.w),
                                child: Icon(Icons.phone_android,
                                    color: AppColors.maroon, size: 20.r),
                              ),
                              prefixIconConstraints:
                                  const BoxConstraints(minWidth: 0),
                              prefixText: '+91 ',
                              prefixStyle: TextStyle(
                                  color: AppColors.maroon,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.sp),
                              hintText: 'Mobile number',
                              hintStyle: TextStyle(
                                  color:
                                      AppColors.textDark.withValues(alpha: 0.3),
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0),
                              counterText: '',
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 16.h),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          12.verticalSpace,
                          Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: AppColors.error, size: 16.r),
                              8.horizontalSpace,
                              Expanded(
                                  child: Text(_error!,
                                      style: TextStyle(
                                          color: AppColors.error,
                                          fontSize: 12.sp))),
                            ],
                          ),
                        ],
                        24.verticalSpace,
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _sending ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.maroon,
                              foregroundColor: AppColors.gold,
                            ),
                            child: _sending
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.w,
                                        color: AppColors.gold))
                                : const Text('Send OTP'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                32.verticalSpace,
                Text(
                  'By continuing, you agree to our Terms & Conditions',
                  style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textDark.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    final digits = _phoneController.text.trim();
    if (digits.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit number');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    final fullNumber = '+91$digits';

    await _authService.sendOtp(
      phoneNumber: fullNumber,
      codeSent: (verificationId) {
        if (!mounted) return;
        setState(() => _sending = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              verificationId: verificationId,
              phoneNumber: fullNumber,
            ),
          ),
        );
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _sending = false;
          _error = message;
        });
      },
      onAutoVerified: (_) {
        // Android auto-verified without needing the OTP screen at all.
        // AuthGate (in main.dart) will pick up the signed-in state automatically.
        if (mounted) setState(() => _sending = false);
      },
    );
  }
}
