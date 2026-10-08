import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'razorpay_payment_service.dart';

@JS('window')
external JSObject get _window;

@JS('openRazorpayWebCheckout')
external void _openRazorpayWebCheckout(JSString optionsJson);

Future<RazorpayPaymentResult> openRazorpayCheckoutImplementation(
    RazorpayCheckoutOptions options) {
  final completer = Completer<RazorpayPaymentResult>();

  final successFunc = ((JSString paymentId, JSString orderId, JSString signature) {
    if (!completer.isCompleted) {
      completer.complete(RazorpayPaymentResult.success(
        paymentId: paymentId.toDart,
        razorpayOrderId: orderId.toDart,
        signature: signature.toDart,
      ));
    }
  }).toJS;

  final errorFunc = ((JSString errorMsg) {
    if (!completer.isCompleted) {
      completer.complete(RazorpayPaymentResult.failure(errorMsg.toDart));
    }
  }).toJS;

  final dismissFunc = (() {
    if (!completer.isCompleted) {
      completer.complete(RazorpayPaymentResult.dismissed());
    }
  }).toJS;

  _window.setProperty('_rzpSuccess'.toJS, successFunc);
  _window.setProperty('_rzpError'.toJS, errorFunc);
  _window.setProperty('_rzpDismiss'.toJS, dismissFunc);

  final appOrderId = options.appOrderId;
  final desc =
      'Order #${appOrderId.length >= 6 ? appOrderId.substring(0, 6).toUpperCase() : appOrderId.toUpperCase()}';

  final optionsMap = {
    'key': options.keyId,
    'amount': options.amount,
    'currency': 'INR',
    'name': 'Maruthi Eats',
    'description': desc,
    'order_id': options.razorpayOrderId,
    'prefill': {
      'contact': options.contact,
      'email': options.email,
    },
    'theme': {
      'color': '#800020',
    },
  };

  try {
    _openRazorpayWebCheckout(jsonEncode(optionsMap).toJS);
  } catch (e) {
    if (!completer.isCompleted) {
      completer.complete(
          RazorpayPaymentResult.failure('Failed to open Razorpay web checkout: $e'));
    }
  }

  return completer.future;
}
