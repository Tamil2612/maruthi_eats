import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  final String id;
  final String code;
  final double amount;
  final double minOrderValue;
  final DateTime? expiryDate;
  final String rules;
  final bool isActive;

  Coupon({
    required this.id,
    required this.code,
    required this.amount,
    required this.minOrderValue,
    this.expiryDate,
    required this.rules,
    this.isActive = true,
  });

  factory Coupon.fromFirestore(String id, Map<String, dynamic> data) {
    return Coupon(
      id: id,
      code: data['code'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      minOrderValue: (data['min_order_value'] ?? 0).toDouble(),
      expiryDate: (data['expiry_date'] is Timestamp)
          ? (data['expiry_date'] as Timestamp).toDate()
          : null,
      rules: data['rules'] ?? '',
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'amount': amount,
      'min_order_value': minOrderValue,
      'expiry_date': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'rules': rules,
      'is_active': isActive,
    };
  }
}
