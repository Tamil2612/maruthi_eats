import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'order_success_screen.dart';
import 'order_history_screen.dart';

const String _functionsRegion = 'asia-south1';

class PaymentConfirmationScreen extends StatefulWidget {
  final String orderId;
  final String razorpayOrderId;
  final String paymentId;
  final String signature;

  const PaymentConfirmationScreen({
    super.key,
    required this.orderId,
    required this.razorpayOrderId,
    required this.paymentId,
    required this.signature,
  });

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  bool _isVerifying = true;
  String _statusMessage = "Please don't close the app. We're verifying your payment.";
  String _title = "Confirming your payment";

  @override
  void initState() {
    super.initState();
    _verifyPayment();
  }

  Future<void> _verifyPayment() async {
    setState(() {
      _isVerifying = true;
      _title = "Confirming your payment";
      _statusMessage = "Please don't close the app. We're verifying your payment.";
    });

    try {
      final result = await FirebaseFunctions.instanceFor(region: _functionsRegion)
          .httpsCallable('razorpay_verify_payment')
          .call({
        'order_id': widget.orderId,
        'razorpay_order_id': widget.razorpayOrderId,
        'razorpay_payment_id': widget.paymentId,
        'razorpay_signature': widget.signature,
      }).timeout(const Duration(seconds: 25));

      final data = Map<String, dynamic>.from(result.data as Map);
      final status = data['status'] as String?;

      if (!mounted) return;

      if (status == 'paid' || status == 'already_paid') {
        setState(() {
          _title = "Payment Confirmed!";
          _statusMessage = "Order placed successfully.";
        });

        // Clear cart ONLY after successful backend verification
        context.read<CartProvider>().clear();

        // Brief delay to show success state before navigating
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(orderId: widget.orderId),
          ),
        );
      } else if (status == 'needs_refund') {
        setState(() {
          _isVerifying = false;
          _title = "Payment Timeout / Refund Required";
          _statusMessage = "Your payment arrived after the order timed out. It will be refunded - please place the order again.";
        });
        // Cart is NOT cleared!
      } else {
        setState(() {
          _isVerifying = false;
          _title = "Verification Pending";
          _statusMessage = "Payment received, but confirmation is processing. Please check Your Orders.";
        });
        // Cart is NOT cleared!
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _title = "We're still checking your payment";
        _statusMessage = "Network timeout while verifying. Your payment is safe. Please retry or check status.";
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _title = "Verification Failed";
        _statusMessage = e.message ?? "Server error during payment verification.";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _title = "Verification Error";
        _statusMessage = "Could not verify payment: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent going back while verifying or in error state without explicit action
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isVerifying)
                  Lottie.asset(
                    'assets/animations/order_placed.json',
                    width: 200.w,
                    height: 200.h,
                    repeat: true,
                  )
                else
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 64.r,
                      color: AppColors.error,
                    ),
                  ),
                32.verticalSpace,
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.maroon,
                  ),
                ),
                16.verticalSpace,
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                24.verticalSpace,
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.maroon.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    'Order ID: ${widget.orderId}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                40.verticalSpace,
                if (_isVerifying)
                  SizedBox(
                    width: 48.w,
                    height: 48.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.w,
                      color: AppColors.maroon,
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: _verifyPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.maroon,
                        foregroundColor: AppColors.gold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'Retry Verification / Check Status',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  16.verticalSpace,
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrderHistoryScreen(),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                    child: Text(
                      'View Your Orders',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.maroon,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
