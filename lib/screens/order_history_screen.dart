import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    return Scaffold(
      appBar: AppBar(title: const Text('Your Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('customer_id', isEqualTo: userId)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.maroon));
          }
          final orders = snapshot.data!.docs
              .map((d) => OrderModel.fromFirestore(d.id, d.data() as Map<String, dynamic>))
              .toList();

          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final order = orders[i];
              return _OrderHistoryCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final OrderModel order;
  const _OrderHistoryCard({required this.order});

  Color _getStatusColor() {
    switch (order.orderStatus) {
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.outForDelivery:
        return AppColors.info;
      case OrderStatus.preparing:
        return AppColors.gold;
      default:
        return AppColors.maroon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = order.createdAt != null
        ? DateFormat('MMM dd, yyyy · hh:mm a').format(order.createdAt!)
        : 'Recent Order';

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
        ),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 6).toUpperCase()}',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp),
                      ),
                      4.verticalSpace,
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 11.sp, color: AppColors.textDark.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: _getStatusColor().withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      orderStatusLabel(order.orderStatus).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              12.verticalSpace,
              const Divider(),
              12.verticalSpace,
              // Product Summary
              Text(
                'ITEMS',
                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: AppColors.textDark.withValues(alpha: 0.4)),
              ),
              8.verticalSpace,
              Text(
                order.items.map((i) => "${i['name']} x ${i['qty']}").join(", "),
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              16.verticalSpace,
              // Footer: Price and CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(fontSize: 10.sp, color: AppColors.textDark.withValues(alpha: 0.5)),
                      ),
                      Text(
                        '₹${order.total.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.maroon),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.maroon,
                      foregroundColor: AppColors.gold,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    child: Text('View Details', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
