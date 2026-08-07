import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../screens/order_tracking_screen.dart';

class LiveOrderTracker extends StatelessWidget {
  const LiveOrderTracker({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customer_id', isEqualTo: userId)
          .where('order_status', whereIn: ['placed', 'confirmed', 'preparing', 'out_for_delivery'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final liveOrders = snapshot.data!.docs
            .map((doc) => OrderModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
            .toList();

        return CarouselSlider.builder(
          itemCount: liveOrders.length,
          itemBuilder: (context, index, realIndex) {
            return _FloatingLiveOrderCard(order: liveOrders[index]);
          },
          options: CarouselOptions(
            height: 75.h,
            viewportFraction: 0.98,
            autoPlay: liveOrders.length > 1,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: false,
            scrollDirection: Axis.horizontal,
          ),
        );
      },
    );
  }
}

class _FloatingLiveOrderCard extends StatelessWidget {
  final OrderModel order;
  const _FloatingLiveOrderCard({required this.order});

  String _getStatusAsset() {
    switch (order.orderStatus) {
      case OrderStatus.outForDelivery:
        return 'assets/gifs/out_for_delivery.gif';
      case OrderStatus.preparing:
        return 'assets/gifs/frying-pan.gif';
      case OrderStatus.confirmed:
        return 'assets/gifs/waiting.gif';
      case OrderStatus.placed:
      default:
        return 'assets/gifs/waiting.gif';
    }
  }

  Color _getStatusColor() {
    switch (order.orderStatus) {
      case OrderStatus.outForDelivery:
        return AppColors.info;
      case OrderStatus.preparing:
        return AppColors.gold;
      case OrderStatus.confirmed:
        return AppColors.success;
      default:
        return AppColors.maroon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final itemsStr = order.items.map((i) => "${i['name']} x ${i['qty']}").join(", ");

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
          ),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            child: Row(
              children: [
                SizedBox(
                  width: 46.r,
                  height: 46.r,
                  child: Image.asset(
                    _getStatusAsset(),
                    fit: BoxFit.contain,
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderStatusLabel(order.orderStatus).toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 9.sp,
                          letterSpacing: 0.5,
                        ),
                      ),
                      4.verticalSpace,
                      Text(
                        itemsStr,
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                8.horizontalSpace,
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.maroon,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    'TRACK',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
