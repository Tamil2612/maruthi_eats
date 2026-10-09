import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  // The bank / Razorpay can take a few seconds to settle a payment, and the
  // network can blip. Retry quietly a few times before bothering the customer.
  static const int _maxAutoAttempts = 4;
  static const Duration _retryDelay = Duration(seconds: 3);
  static const Set<String> _retryableCodes = {
    'unavailable',
    'deadline-exceeded',
    'internal',
    'aborted',
  };

  bool _isVerifying = true;
  // true = a real problem (red icon); false = "still confirming" (calm icon).
  bool _isHardError = false;
  String _statusMessage = "Please don't close the app. We're verifying your payment.";
  String _title = "Confirming your payment";

  @override
  void initState() {
    super.initState();
    _verifyPayment();
  }

  void _showState({
    required String title,
    required String message,
    bool verifying = false,
    bool hardError = false,
  }) {
    if (!mounted) return;
    setState(() {
      _isVerifying = verifying;
      _isHardError = hardError;
      _title = title;
      _statusMessage = message;
    });
  }

  /// The webhook may have confirmed the payment while the app was retrying.
  Future<bool> _isPaidInFirestore() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();
      final data = snap.data();
      return data != null &&
          data['payment_status'] == 'paid' &&
          data['order_status'] != 'pending_payment';
    } catch (_) {
      return false;
    }
  }

  Future<void> _onPaid() async {
    if (!mounted) return;
    _showState(
      title: "Payment Confirmed!",
      message: "Order placed successfully.",
      verifying: true,
    );

    // Clear cart ONLY after the backend has confirmed the payment.
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
  }

  Future<void> _verifyPayment() async {
    _showState(
      title: "Confirming your payment",
      message: "Please don't close the app. We're verifying your payment.",
      verifying: true,
    );

    for (var attempt = 1; attempt <= _maxAutoAttempts; attempt++) {
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
          await _onPaid();
          return;
        }

        if (status == 'needs_refund') {
          // Cart is NOT cleared: the customer has to place the order again.
          _showState(
            title: "Payment Timeout / Refund Required",
            message: "Your payment arrived after the order timed out. "
                "It will be refunded - please place the order again.",
            hardError: true,
          );
          return;
        }
        // 'pending' (still settling) or anything unexpected: keep waiting below.
      } on FirebaseFunctionsException catch (e) {
        if (!mounted) return;
        if (!_retryableCodes.contains(e.code)) {
          // Cart is NOT cleared. Money may have been taken, so say so clearly.
          _showState(
            title: "Verification Failed",
            message: e.message ?? "Server error during payment verification.",
            hardError: true,
          );
          return;
        }
      } on TimeoutException {
        // Slow network: try again below.
      } catch (_) {
        // Network blip: try again below.
      }

      if (!mounted) return;
      if (await _isPaidInFirestore()) {
        await _onPaid();
        return;
      }

      if (attempt < _maxAutoAttempts) {
        _showState(
          title: "Confirming your payment",
          message: "Still waiting for your bank to confirm... ($attempt/$_maxAutoAttempts)",
          verifying: true,
        );
        await Future.delayed(_retryDelay);
        if (!mounted) return;
      }
    }

    // Cart is NOT cleared. The server keeps confirming in the background.
    _showState(
      title: "We're still confirming your payment",
      message: "Your payment is safe. It can take a minute to confirm. "
          "Tap 'Check again', or look in Your Orders shortly.",
    );
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
                      color: (_isHardError ? AppColors.error : AppColors.maroon)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isHardError
                          ? Icons.error_outline_rounded
                          : Icons.hourglass_top_rounded,
                      size: 64.r,
                      color: _isHardError ? AppColors.error : AppColors.maroon,
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
                        'Check again',
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