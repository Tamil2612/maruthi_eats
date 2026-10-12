import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'razorpay_payment_service.dart';

Future<RazorpayPaymentResult> openRazorpayCheckoutImplementation(
    RazorpayCheckoutOptions options) async {
  final completer = Completer<RazorpayPaymentResult>();
  final razorpay = Razorpay();

  void onSuccess(PaymentSuccessResponse response) {
    if (!completer.isCompleted) {
      completer.complete(RazorpayPaymentResult.success(
        paymentId: response.paymentId ?? '',
        razorpayOrderId: response.orderId ?? options.razorpayOrderId,
        signature: response.signature ?? '',
      ));
    }
    razorpay.clear();
  }

  void onError(PaymentFailureResponse response) {
    if (!completer.isCompleted) {
      if (response.code == Razorpay.PAYMENT_CANCELLED) {
        completer.complete(RazorpayPaymentResult.dismissed());
      } else if (response.code == Razorpay.NETWORK_ERROR) {
        // A dropped connection is NOT a cancellation: the customer may already have
        // paid. The server confirms such payments by itself within a couple of
        // minutes, so say that instead of "Payment cancelled".
        completer.complete(RazorpayPaymentResult.failure(
            'Network problem during payment. If money was deducted, your order '
                'will be confirmed automatically in a few minutes.'));
      } else {
        final msg = response.message != null && response.message!.isNotEmpty
            ? response.message!
            : 'Payment failed (Code ${response.code})';
        completer.complete(RazorpayPaymentResult.failure(msg));
      }
    }
    razorpay.clear();
  }

  void onExternalWallet(ExternalWalletResponse response) {
    if (!completer.isCompleted) {
      completer.complete(RazorpayPaymentResult.failure(
          'External wallet selected: ${response.walletName}'));
    }
    razorpay.clear();
  }

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);

  try {
    final appOrderId = options.appOrderId;
    final desc =
        'Order #${appOrderId.length >= 6 ? appOrderId.substring(0, 6).toUpperCase() : appOrderId.toUpperCase()}';

    razorpay.open({
      'key': options.keyId,
      'amount': options.amount,
      'order_id': options.razorpayOrderId,
      'currency': 'INR',
      'name': 'Maruthi Eats',
      'description': desc,
      'prefill': {
        'contact': options.contact,
        'email': options.email,
      },
      'timeout': 600,
    });
  } catch (e) {
    if (!completer.isCompleted) {
      completer.complete(
          RazorpayPaymentResult.failure('Could not launch Razorpay SDK: $e'));
    }
    razorpay.clear();
  }

  return completer.future;
}