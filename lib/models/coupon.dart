import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  final String id;
  final String code;
  final double amount;
  final double minOrderValue;
  final DateTime? expiryDate;
  final String rules;
  final bool isActive;
  final bool isFirstOrderOnly;
  final int? maxUsesPerUser;
  final int? maxGlobalUses;
  final int currentGlobalUses;

  Coupon({
    required this.id,
    required this.code,
    required this.amount,
    required this.minOrderValue,
    this.expiryDate,
    required this.rules,
    this.isActive = true,
    this.isFirstOrderOnly = false,
    this.maxUsesPerUser,
    this.maxGlobalUses,
    this.currentGlobalUses = 0,
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
      isFirstOrderOnly: data['is_first_order_only'] ?? false,
      maxUsesPerUser: data['max_uses_per_user'] != null
          ? (data['max_uses_per_user'] as num).toInt()
          : null,
      maxGlobalUses: data['max_global_uses'] != null
          ? (data['max_global_uses'] as num).toInt()
          : null,
      currentGlobalUses: (data['current_global_uses'] ?? 0).toInt(),
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
      'is_first_order_only': isFirstOrderOnly,
      if (maxUsesPerUser != null) 'max_uses_per_user': maxUsesPerUser,
      if (maxGlobalUses != null) 'max_global_uses': maxGlobalUses,
      'current_global_uses': currentGlobalUses,
    };
  }
}
