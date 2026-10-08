import 'razorpay_checkout_stub.dart'
    if (dart.library.js_interop) 'razorpay_checkout_web.dart'
    if (dart.library.html) 'razorpay_checkout_web.dart'
    if (dart.library.io) 'razorpay_checkout_mobile.dart';

class RazorpayCheckoutOptions {
  final String keyId;
  final int amount;
  final String razorpayOrderId;
  final String appOrderId;
  final String contact;
  final String email;

  RazorpayCheckoutOptions({
    required this.keyId,
    required this.amount,
    required this.razorpayOrderId,
    required this.appOrderId,
    required this.contact,
    required this.email,
  });
}

class RazorpayPaymentResult {
  final bool isSuccess;
  final String? paymentId;
  final String? razorpayOrderId;
  final String? signature;
  final String? errorMessage;
  final bool isDismissed;

  RazorpayPaymentResult.success({
    required this.paymentId,
    required this.razorpayOrderId,
    required this.signature,
  })  : isSuccess = true,
        errorMessage = null,
        isDismissed = false;

  RazorpayPaymentResult.failure(this.errorMessage)
      : isSuccess = false,
        paymentId = null,
        razorpayOrderId = null,
        signature = null,
        isDismissed = false;

  RazorpayPaymentResult.dismissed()
      : isSuccess = false,
        paymentId = null,
        razorpayOrderId = null,
        signature = null,
        errorMessage = 'Payment cancelled',
        isDismissed = true;
}

class RazorpayPaymentService {
  /// Launches Razorpay checkout modal on native platforms or Checkout.js on Web.
  static Future<RazorpayPaymentResult> openCheckout(
      RazorpayCheckoutOptions options) {
    return openRazorpayCheckoutImplementation(options);
  }
}
