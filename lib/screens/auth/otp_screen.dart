import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({super.key, required this.verificationId, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _verifying = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Verification'),
        backgroundColor: AppColors.white.withValues(alpha: 0.0),
        foregroundColor: AppColors.maroon,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Card(
            elevation: 4,
            shadowColor: AppColors.maroon.withValues(alpha: 0.1),
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.mark_email_read_outlined, color: AppColors.maroon, size: 48.r),
                  16.verticalSpace,
                  Text(
                    'Verify Details',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
                  ),
                  8.verticalSpace,
                  Text(
                    'We\'ve sent a 6-digit code to\n${widget.phoneNumber}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.6), height: 1.4.h),
                  ),
                  32.verticalSpace,
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24.sp, letterSpacing: 12.w, fontWeight: FontWeight.w700, color: AppColors.maroon),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      hintStyle: TextStyle(color: AppColors.maroon.withValues(alpha: 0.1), letterSpacing: 12.w),
                      fillColor: AppColors.cream.withValues(alpha: 0.3),
                    ),
                  ),
                  if (_error != null) ...[
                    16.verticalSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 16.r),
                        8.horizontalSpace,
                        Flexible(child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 12.sp))),
                      ],
                    ),
                  ],
                  32.verticalSpace,
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifying ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.maroon,
                        foregroundColor: AppColors.gold,
                      ),
                      child: _verifying
                          ? SizedBox(
                              height: 20.h, width: 20.w,
                              child: CircularProgressIndicator(strokeWidth: 2.w, color: AppColors.gold))
                          : const Text('Verify & Continue'),
                    ),
                  ),
                  16.verticalSpace,
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Change Number', style: TextStyle(color: AppColors.maroon, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verify() async {
    if (_otpController.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      await _authService.verifyOtp(
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
      );

      if (!mounted) return;
      // AuthGate will detect the new auth state and route accordingly.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() {
        _verifying = false;
        _error = e.toString().contains('PERMISSION_DENIED')
            ? 'Firestore Permission Denied. Check your Security Rules.'
            : 'Error: $e';
      });
    }
  }
}
