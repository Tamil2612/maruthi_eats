import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/order_status_stepper.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Order')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator(color: AppColors.maroon));
          }

          final order = OrderModel.fromFirestore(
              snapshot.data!.id, snapshot.data!.data() as Map<String, dynamic>);

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppColors.maroon,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${order.id.substring(0, 6).toUpperCase()}',
                          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13.sp)),
                      4.verticalSpace,
                      Text(orderStatusLabel(order.orderStatus),
                          style: TextStyle(color: AppColors.white, fontSize: 18.sp, fontWeight: FontWeight.w700)),
                      8.verticalSpace,
                      Text(
                        order.paymentMode == 'upi'
                            ? 'Paid via UPI · ${order.paymentStatus}'
                            : 'Cash on Delivery · ${order.paymentStatus == 'cod_collected' ? 'Collected' : 'Pay on arrival'}',
                        style: TextStyle(color: AppColors.white.withValues(alpha: 0.7), fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
                28.verticalSpace,
                OrderStatusStepper(currentStatus: order.orderStatus),
                12.verticalSpace,
                const Divider(),
                12.verticalSpace,
                Text('Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp)),
                8.verticalSpace,
                ...order.items.map((item) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item['name']} × ${item['qty']}', style: TextStyle(fontSize: 13.sp)),
                          Text('₹${(item['price'] * item['qty']).toStringAsFixed(0)}', style: TextStyle(fontSize: 13.sp)),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp)),
                    Text('₹${order.total.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.maroon, fontSize: 15.sp)),
                  ],
                ),
                16.verticalSpace,
                Text('Delivering to', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp)),
                6.verticalSpace,
                Text(order.deliveryAddress, style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7), fontSize: 12.sp)),
              ],
            ),
          );
        },
      ),
    );
  }
}
