import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/menu_item.dart';
import '../models/offer.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'order_tracking_screen.dart';
import 'cart_screen.dart';
import 'full_menu_screen.dart';

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
            return const Center(
                child: CircularProgressIndicator(color: AppColors.maroon));
          }
          final orders = snapshot.data!.docs
              .map((d) => OrderModel.fromFirestore(
                  d.id, d.data() as Map<String, dynamic>))
              .toList();

          if (orders.isEmpty) {
            return _buildEmptyState(context);
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 80.r, color: AppColors.maroon.withValues(alpha: 0.1)),
            24.verticalSpace,
            Text(
              'No orders yet!',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
            ),
            8.verticalSpace,
            Text(
              'Your delicious meals will appear here once you place an order.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textDark.withValues(alpha: 0.5)),
            ),
            32.verticalSpace,
            SizedBox(
              width: 200.w,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const FullMenuScreen()),
                ),
                child: const Text('Browse Menu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderHistoryCard extends StatefulWidget {
  final OrderModel order;

  const _OrderHistoryCard({required this.order});

  @override
  State<_OrderHistoryCard> createState() => _OrderHistoryCardState();
}

class _OrderHistoryCardState extends State<_OrderHistoryCard> {
  bool _reordering = false;

  Color _getStatusColor() {
    switch (widget.order.orderStatus) {
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.outForDelivery:
        return Colors.cyan;
      case OrderStatus.preparing:
        return AppColors.gold;
      case OrderStatus.placed:
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _handleRepeatOrder() async {
    setState(() => _reordering = true);

    try {
      final cart = context.read<CartProvider>();
      final db = FirebaseFirestore.instance;

      List<String> outOfStock = [];
      int addedCount = 0;

      // Filter out free items as they are added by addOffer logic
      final itemsToProcess =
          widget.order.items.where((i) => i['is_free'] != true).toList();

      for (final itemData in itemsToProcess) {
        final itemId = itemData['item_id'] as String;
        final isOffer = itemData['is_offer'] == true;
        final qty = (itemData['qty'] ?? 1) as int;

        if (isOffer) {
          // Handle Offer
          final storedOfferId = itemData['offer_id'];
          final hasStoredOfferId =
              storedOfferId is String && storedOfferId.isNotEmpty;
          String offerDocId = hasStoredOfferId ? storedOfferId : itemId;
          if (!hasStoredOfferId && itemId.startsWith('offer_')) {
            offerDocId = itemId.replaceFirst('offer_', '');
          }
          if (!hasStoredOfferId && itemId.startsWith('bogo_')) {
            // Legacy orders did not store an explicit offer ID. Remove only
            // the known wrapper and suffix so IDs containing underscores work.
            offerDocId = itemId.substring('bogo_'.length);
            if (offerDocId.endsWith('_buy') || offerDocId.endsWith('_get')) {
              offerDocId = offerDocId.substring(0, offerDocId.length - 4);
            }
          }

          final offerDoc = await db.collection('offers').doc(offerDocId).get();
          if (offerDoc.exists) {
            final offer =
                OfferModel.fromFirestore(offerDoc.id, offerDoc.data()!);
            final expired = offer.expiryDate != null &&
                offer.expiryDate!.isBefore(DateTime.now());

            if (offer.isActive && !expired) {
              if (offer.type == OfferType.bogo) {
                final buyItem = await _fetchMenuItem(offer.buyItemId!);
                final getItem = await _fetchMenuItem(offer.getItemId!);
                if (buyItem != null &&
                    buyItem.available &&
                    getItem != null &&
                    getItem.available) {
                  // Add BOGO set (the addOffer logic handles buyQty/getQty multipliers if we call it multiple times)
                  // But wait, the order stores the total qty. If buyQty is 1 and order has qty 2, it means user added it twice.
                  final sets = qty ~/ offer.buyQty;
                  for (int s = 0; s < sets; s++) {
                    cart.addOffer(offer, buyItem: buyItem, getItem: getItem);
                  }
                  addedCount++;
                } else {
                  outOfStock.add(offer.title);
                }
              } else {
                // Combo
                // Check if all items in combo are available? (Optional, but safer)
                for (int q = 0; q < qty; q++) {
                  cart.addOffer(offer);
                }
                addedCount++;
              }
            } else {
              outOfStock.add(offer.title);
            }
          } else {
            outOfStock.add(itemData['name']);
          }
        } else {
          // Normal MenuItem
          final menuItem = await _fetchMenuItem(itemId);
          if (menuItem != null && menuItem.available) {
            for (int q = 0; q < qty; q++) {
              cart.addItem(menuItem);
            }
            addedCount++;
          } else {
            outOfStock.add(itemData['name']);
          }
        }
      }

      if (mounted) {
        if (outOfStock.isNotEmpty) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Some items unavailable'),
              content: Text(
                  'The following items were not added as they are currently out of stock or inactive:\n\n• ${outOfStock.join("\n• ")}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (addedCount > 0) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CartScreen()));
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else if (addedCount > 0) {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const CartScreen()));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error repeating order: $e')));
      }
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  Future<MenuItem?> _fetchMenuItem(String id) async {
    final doc =
        await FirebaseFirestore.instance.collection('menu_items').doc(id).get();
    if (!doc.exists) return null;
    return MenuItem.fromFirestore(doc.id, doc.data()!);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.order.createdAt != null
        ? DateFormat('MMM dd, yyyy · hh:mm a').format(widget.order.createdAt!)
        : 'Recent Order';

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(orderId: widget.order.id)),
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
                        'Order #${widget.order.id.substring(0, 6).toUpperCase()}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14.sp),
                      ),
                      4.verticalSpace,
                      Text(
                        dateStr,
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textDark.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                          color: _getStatusColor().withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      orderStatusLabel(widget.order.orderStatus).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: _getStatusColor(),
                        letterSpacing: 0.3,
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
                style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.textDark.withValues(alpha: 0.4)),
              ),
              8.verticalSpace,
              Text(
                widget.order.items
                    .map((i) => "${i['name']} x ${i['qty']}")
                    .join(", "),
                style: TextStyle(
                    fontSize: 12.sp, fontWeight: FontWeight.w500, height: 1.4),
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
                        style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.textDark.withValues(alpha: 0.5)),
                      ),
                      Text(
                        '₹${widget.order.total.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.maroon),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (widget.order.orderStatus == OrderStatus.delivered ||
                          widget.order.orderStatus == OrderStatus.cancelled)
                        TextButton(
                          onPressed: _reordering ? null : _handleRepeatOrder,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.maroon,
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                          ),
                          child: _reordering
                              ? SizedBox(
                                  width: 14.r,
                                  height: 14.r,
                                  child: const CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.maroon))
                              : Text('Repeat Order',
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700)),
                        ),
                      8.horizontalSpace,
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => OrderTrackingScreen(
                                  orderId: widget.order.id)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.order.orderStatus ==
                                      OrderStatus.delivered ||
                                  widget.order.orderStatus ==
                                      OrderStatus.cancelled
                              ? AppColors.maroon
                              : Colors.green,
                          foregroundColor: widget.order.orderStatus ==
                                      OrderStatus.delivered ||
                                  widget.order.orderStatus ==
                                      OrderStatus.cancelled
                              ? AppColors.gold
                              : AppColors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r)),
                        ),
                        child: Text(
                          (widget.order.orderStatus == OrderStatus.delivered ||
                                  widget.order.orderStatus ==
                                      OrderStatus.cancelled)
                              ? 'Details'
                              : 'Track Now',
                          style: TextStyle(
                              fontSize: 12.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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
