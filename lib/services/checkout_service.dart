import 'package:cloud_functions/cloud_functions.dart';

class CheckoutPreviewResult {
  final bool isAvailable;
  final String statusCode;
  final String statusMessage;
  final double distanceKm;
  final double deliveryFee;
  final bool isDeliverable;
  final String deliveryMessage;
  final double minimumOrderValue;
  final bool meetsMinimumOrder;
  final String minimumOrderMessage;

  CheckoutPreviewResult({
    required this.isAvailable,
    required this.statusCode,
    required this.statusMessage,
    required this.distanceKm,
    required this.deliveryFee,
    required this.isDeliverable,
    required this.deliveryMessage,
    required this.minimumOrderValue,
    required this.meetsMinimumOrder,
    required this.minimumOrderMessage,
  });

  factory CheckoutPreviewResult.fromMap(Map<String, dynamic> map) {
    return CheckoutPreviewResult(
      isAvailable: map['is_available'] ?? true,
      statusCode: map['status_code'] ?? 'OPEN',
      statusMessage: map['status_message'] ?? '',
      distanceKm: (map['distance_km'] ?? 0.0).toDouble(),
      deliveryFee: (map['delivery_fee'] ?? 30.0).toDouble(),
      isDeliverable: map['is_deliverable'] ?? true,
      deliveryMessage: map['delivery_message'] ?? '',
      minimumOrderValue: (map['minimum_order_value'] ?? 150.0).toDouble(),
      meetsMinimumOrder: map['meets_minimum_order'] ?? true,
      minimumOrderMessage: map['minimum_order_message'] ?? '',
    );
  }
}

class CheckoutService {
  static Future<CheckoutPreviewResult> getCheckoutPreview({
    required double latitude,
    required double longitude,
    required double subtotal,
  }) async {
    final res = await FirebaseFunctions.instanceFor(region: 'asia-south1')
        .httpsCallable('get_checkout_preview')
        .call({
      'latitude': latitude,
      'longitude': longitude,
      'subtotal': subtotal,
    });

    final data = Map<String, dynamic>.from(res.data as Map);
    return CheckoutPreviewResult.fromMap(data);
  }
}
