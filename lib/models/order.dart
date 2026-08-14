import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { placed, confirmed, preparing, outForDelivery, delivered, cancelled }

enum PaymentMode { upi, cod }

OrderStatus orderStatusFromString(String status) {
  switch (status) {
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'preparing':
      return OrderStatus.preparing;
    case 'out_for_delivery':
      return OrderStatus.outForDelivery;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'placed':
    default:
      return OrderStatus.placed;
  }
}

String orderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.placed:
      return 'Order Placed';
    case OrderStatus.confirmed:
      return 'Confirmed';
    case OrderStatus.preparing:
      return 'Preparing';
    case OrderStatus.outForDelivery:
      return 'Out for Delivery';
    case OrderStatus.delivered:
      return 'Delivered';
    case OrderStatus.cancelled:
      return 'Cancelled';
  }
}

class OrderModel {
  final String id;
  final String customerId;
  final List<Map<String, dynamic>> items;
  final double total;
  final double itemTotal;
  final double deliveryFee;
  final double taxes;
  final String? couponCode;
  final double couponDiscount;
  final String paymentMode; // 'upi' | 'cod'
  final String paymentStatus;
  final OrderStatus orderStatus;
  final String deliveryAddress;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.items,
    required this.total,
    required this.itemTotal,
    required this.deliveryFee,
    required this.taxes,
    this.couponCode,
    this.couponDiscount = 0.0,
    required this.paymentMode,
    required this.paymentStatus,
    required this.orderStatus,
    required this.deliveryAddress,
    this.createdAt,
  });

  factory OrderModel.fromFirestore(String id, Map<String, dynamic> data) {
    return OrderModel(
      id: id,
      customerId: data['customer_id'] ?? '',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      total: (data['total'] ?? 0).toDouble(),
      itemTotal: (data['item_total'] ?? (data['total'] ?? 0)).toDouble(),
      deliveryFee: (data['delivery_fee'] ?? 0).toDouble(),
      taxes: (data['taxes'] ?? 0).toDouble(),
      couponCode: data['coupon_code'],
      couponDiscount: (data['coupon_discount'] ?? 0.0).toDouble(),
      paymentMode: data['payment_mode'] ?? 'cod',
      paymentStatus: data['payment_status'] ?? 'pending',
      orderStatus: orderStatusFromString(data['order_status'] ?? 'placed'),
      deliveryAddress: data['delivery_address'] ?? '',
      createdAt: (data['created_at'] is Timestamp)
          ? (data['created_at'] as Timestamp).toDate()
          : null,
    );
  }
}
