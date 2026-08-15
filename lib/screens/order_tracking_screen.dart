import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import '../widgets/order_status_stepper.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Track Order'),
        centerTitle: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading order tracking'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator(color: AppColors.maroon));
          }

          final order = OrderModel.fromFirestore(
              snapshot.data!.id, snapshot.data!.data() as Map<String, dynamic>);

          // Delivered orders get a completely different, celebratory screen
          // instead of the live-tracking layout.
          if (order.orderStatus == OrderStatus.delivered) {
            return _DeliveredOrderView(order: order);
          }

          if (order.orderStatus == OrderStatus.cancelled) {
            return _CancelledOrderView(order: order);
          }

          return _ActiveTrackingView(order: order);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACTIVE TRACKING (placed / confirmed / preparing / out for delivery)
// ─────────────────────────────────────────────────────────────

class _ActiveTrackingView extends StatelessWidget {
  final OrderModel order;
  const _ActiveTrackingView({required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrderSummaryHeader(order: order),
          24.verticalSpace,
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 16.r, color: AppColors.maroon),
                    8.horizontalSpace,
                    Text('Order Progress',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp)),
                  ],
                ),
                16.verticalSpace,
                OrderStatusStepper(currentStatus: order.orderStatus),
              ],
            ),
          ),
          20.verticalSpace,
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 16.r, color: AppColors.maroon),
                    8.horizontalSpace,
                    Text('Items Ordered',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp)),
                  ],
                ),
                12.verticalSpace,
                ...order.items.map((item) => _OrderedItemRow(item: item)),
                16.verticalSpace,
                Divider(color: AppColors.grey.withValues(alpha: 0.2), height: 1),
                16.verticalSpace,
                _TrackingBillDetails(order: order),
              ],
            ),
          ),
          20.verticalSpace,
          _DeliveryInfoCard(order: order),
          20.verticalSpace,
          const _HelpSection(),
          100.verticalSpace,
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.maroon.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _OrderSummaryHeader extends StatelessWidget {
  final OrderModel order;
  const _OrderSummaryHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateStr = order.createdAt != null
        ? DateFormat('MMM dd, hh:mm a').format(order.createdAt!)
        : 'Recently';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.maroon, AppColors.maroonDark],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(color: AppColors.maroon.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Text('#${order.id.substring(0, 6).toUpperCase()}',
                    style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 12.sp, letterSpacing: 0.5)),
              ),
              Text(dateStr,
                  style: TextStyle(color: AppColors.white.withValues(alpha: 0.55), fontSize: 11.sp)),
            ],
          ),
          16.verticalSpace,
          Text(orderStatusLabel(order.orderStatus),
              style: TextStyle(color: AppColors.white, fontSize: 23.sp, fontWeight: FontWeight.w900)),
          6.verticalSpace,
          Text(
            _statusSubtext(order.orderStatus),
            style: TextStyle(color: AppColors.white.withValues(alpha: 0.65), fontSize: 12.5.sp),
          ),
          14.verticalSpace,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  order.paymentMode == 'upi' ? Icons.verified_user : Icons.payments_outlined,
                  color: AppColors.gold,
                  size: 14.r,
                ),
                8.horizontalSpace,
                Expanded(
                  child: Text(
                    order.paymentMode == 'upi'
                        ? 'Paid via UPI · ${order.paymentStatus}'
                        : 'Cash on Delivery · ${order.paymentStatus == 'cod_collected' ? 'Collected' : 'Pay on arrival'}',
                    style: TextStyle(color: AppColors.white.withValues(alpha: 0.85), fontSize: 12.sp, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusSubtext(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return "We've received your order — the kitchen will confirm shortly.";
      case OrderStatus.confirmed:
        return 'Your order is confirmed and will start preparing soon.';
      case OrderStatus.preparing:
        return 'The kitchen is preparing your food fresh.';
      case OrderStatus.outForDelivery:
        return 'On its way to you now.';
      default:
        return '';
    }
  }
}

class _OrderedItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _OrderedItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isFree = item['is_free'] == true;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8.r,
            height: 8.r,
            margin: EdgeInsets.only(top: 5.h),
            decoration: BoxDecoration(
              color: isFree ? AppColors.success : AppColors.maroon.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['name']} × ${item['qty']}',
                  style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
                if (item['offer_description'] != null)
                  Text(
                    item['offer_description'],
                    style: TextStyle(fontSize: 10.sp, color: AppColors.textDark.withValues(alpha: 0.4)),
                  ),
              ],
            ),
          ),
          Text(
            isFree ? 'FREE' : '₹${(item['price'] * item['qty']).toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: isFree ? AppColors.success : AppColors.textDark.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingBillDetails extends StatelessWidget {
  final OrderModel order;
  const _TrackingBillDetails({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _billRow('Item Total', order.itemTotal),
        if (order.couponDiscount > 0)
          _billRow('Coupon (${order.couponCode ?? "Applied"})', -order.couponDiscount, isDiscount: true),
        _billRow('Delivery Fee', order.deliveryFee),
        if (order.taxes > 0) _billRow('Taxes & Charges', order.taxes),
        14.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Paid / Payable', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900)),
            Text('₹${order.total.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: AppColors.maroon)),
          ],
        ),
      ],
    );
  }

  Widget _billRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5.sp,
              color: isDiscount ? AppColors.success : AppColors.textDark.withValues(alpha: 0.5),
              fontWeight: isDiscount ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            '${amount < 0 ? "-" : ""}₹${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12.5.sp,
              color: isDiscount ? AppColors.success : AppColors.textDark.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryInfoCard extends StatelessWidget {
  final OrderModel order;
  const _DeliveryInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.location_on;
    final label = order.addressLabel?.toLowerCase() ?? '';
    if (label.contains('home')) icon = Icons.home;
    if (label.contains('work') || label.contains('office')) icon = Icons.work;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.r, color: AppColors.maroon),
              8.horizontalSpace,
              Text(
                'Delivering to ${order.addressLabel ?? "Address"}',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.sp),
              ),
            ],
          ),
          12.verticalSpace,
          Text(
            order.deliveryAddress,
            style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.6), fontSize: 12.sp, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {},
        icon: Icon(Icons.help_outline, size: 18.r, color: AppColors.maroon),
        label: Text('Need help with this order?',
            style: TextStyle(color: AppColors.maroon, fontWeight: FontWeight.bold, fontSize: 13.sp)),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          backgroundColor: AppColors.maroon.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CANCELLED ORDER VIEW
// ─────────────────────────────────────────────────────────────

class _CancelledOrderView extends StatelessWidget {
  final OrderModel order;
  const _CancelledOrderView({required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
      child: Column(
        children: [
          Container(
            width: 84.r,
            height: 84.r,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded, color: AppColors.error, size: 44.r),
          ),
          20.verticalSpace,
          Text('Order Cancelled', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          8.verticalSpace,
          Text(
            'Order #${order.id.substring(0, 6).toUpperCase()} was cancelled.',
            style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.55), fontSize: 13.sp),
          ),
          28.verticalSpace,
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) => _OrderedItemRow(item: item)),
                14.verticalSpace,
                Divider(color: AppColors.grey.withValues(alpha: 0.2), height: 1),
                14.verticalSpace,
                _TrackingBillDetails(order: order),
              ],
            ),
          ),
          24.verticalSpace,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Back to Menu'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DELIVERED ORDER VIEW — distinct, celebratory, professional
// ─────────────────────────────────────────────────────────────

class _DeliveredOrderView extends StatefulWidget {
  final OrderModel order;
  const _DeliveredOrderView({required this.order});

  @override
  State<_DeliveredOrderView> createState() => _DeliveredOrderViewState();
}

class _DeliveredOrderViewState extends State<_DeliveredOrderView> {
  int _rating = 0;
  bool _submittingRating = false;
  bool _ratingSubmitted = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final dateStr = order.createdAt != null
        ? DateFormat('MMM dd, hh:mm a').format(order.createdAt!)
        : '';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 28.h, 16.w, 40.h),
      child: Column(
        children: [
          // Success hero
          Container(
            width: 96.r,
            height: 96.r,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10)),
              ],
            ),
            child: Icon(Icons.check_rounded, color: AppColors.white, size: 52.r),
          ),
          20.verticalSpace,
          Text('Delivered!',
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          6.verticalSpace,
          Text(
            'Order #${order.id.substring(0, 6).toUpperCase()} · $dateStr',
            style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.5), fontSize: 12.5.sp),
          ),
          28.verticalSpace,

          // Rating card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: AppColors.maroon,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(color: AppColors.maroon.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _ratingSubmitted ? 'Thanks for the feedback!' : 'How was your food?',
                  style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15.sp),
                ),
                14.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final filled = i < _rating;
                    return IconButton(
                      onPressed: _ratingSubmitted
                          ? null
                          : () => setState(() => _rating = i + 1),
                      icon: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        color: AppColors.gold,
                        size: 32.r,
                      ),
                    );
                  }),
                ),
                if (!_ratingSubmitted && _rating > 0) ...[
                  10.verticalSpace,
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submittingRating ? null : () => _submitRating(order.id),
                      child: _submittingRating
                          ? SizedBox(
                        height: 18.r,
                        width: 18.r,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark),
                      )
                          : const Text('Submit Rating'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          24.verticalSpace,

          // Order summary
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 16.r, color: AppColors.maroon),
                    8.horizontalSpace,
                    Text('Order Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp)),
                  ],
                ),
                12.verticalSpace,
                ...order.items.map((item) => _OrderedItemRow(item: item)),
                14.verticalSpace,
                Divider(color: AppColors.grey.withValues(alpha: 0.2), height: 1),
                14.verticalSpace,
                _TrackingBillDetails(order: order),
              ],
            ),
          ),
          24.verticalSpace,

          // Actions
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Order Again'),
            ),
          ),
          10.verticalSpace,
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.support_agent_outlined, size: 18.r),
              label: const Text('Get Help'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRating(String orderId) async {
    setState(() => _submittingRating = true);
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'rating': _rating,
      });
      if (mounted) setState(() => _ratingSubmitted = true);
    } catch (_) {
      if (mounted) {
        setState(() => _submittingRating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit rating. Please try again.')),
        );
      }
    }
  }
}