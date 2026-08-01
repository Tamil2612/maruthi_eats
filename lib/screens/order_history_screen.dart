import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
              return Card(
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  title: Text('Order #${order.id.substring(0, 6).toUpperCase()}',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
                  subtitle: Text('${order.items.length} items · ₹${order.total.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12.sp)),
                  trailing: Chip(label: Text(orderStatusLabel(order.orderStatus), style: TextStyle(fontSize: 10.sp))),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
