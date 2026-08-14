import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/offer.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'skeleton_loaders.dart';

class OfferDetailsSheet extends StatefulWidget {
  final OfferModel offer;
  const OfferDetailsSheet({super.key, required this.offer});

  @override
  State<OfferDetailsSheet> createState() => _OfferDetailsSheetState();
}

class _OfferDetailsSheetState extends State<OfferDetailsSheet> {
  MenuItem? _buyItem;
  MenuItem? _getItem;
  bool _loadingItems = false;

  @override
  void initState() {
    super.initState();
    if (widget.offer.type == OfferType.bogo) {
      _fetchBogoItems();
    }
  }

  Future<void> _fetchBogoItems() async {
    setState(() => _loadingItems = true);
    try {
      final db = FirebaseFirestore.instance;
      
      // Fetch Buy Item
      if (widget.offer.buyItemId != null) {
        final buyDoc = await db.collection('menu_items').doc(widget.offer.buyItemId).get();
        if (buyDoc.exists) {
          _buyItem = MenuItem.fromFirestore(buyDoc.id, buyDoc.data()!);
        }
      }

      // Fetch Get Item
      if (widget.offer.getItemId != null) {
        final getDoc = await db.collection('menu_items').doc(widget.offer.getItemId).get();
        if (getDoc.exists) {
          _getItem = MenuItem.fromFirestore(getDoc.id, getDoc.data()!);
        }
      }
    } catch (e) {
      debugPrint("Error fetching BOGO items: $e");
    } finally {
      if (mounted) setState(() => _loadingItems = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Indicator
          Container(
            margin: EdgeInsets.symmetric(vertical: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 40.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  if (offer.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: CachedNetworkImage(
                        imageUrl: offer.imageUrl,
                        height: 200.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => ShimmerLoader(child: Container(color: Colors.white)),
                        errorWidget: (context, url, error) => Image.asset('assets/icons/placeholder_food.png', fit: BoxFit.cover),
                      ),
                    ),
                  20.verticalSpace,
                  
                  // Title & Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          offer.title,
                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: AppColors.maroon),
                        ),
                      ),
                      _buildTypeBadge(offer.type),
                    ],
                  ),
                  8.verticalSpace,
                  Text(
                    offer.description,
                    style: TextStyle(fontSize: 14.sp, color: AppColors.textDark.withValues(alpha: 0.6), height: 1.4),
                  ),
                  24.verticalSpace,

                  // Items Section
                  Text(
                    offer.type == OfferType.combo ? 'What\u0027s in the bundle:' : 'Offer Details:',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800),
                  ),
                  16.verticalSpace,
                  
                  if (_loadingItems)
                    const Center(child: CircularProgressIndicator(color: AppColors.maroon))
                  else if (offer.type == OfferType.combo)
                    ...offer.bundleItems.map((item) => _itemRow(item.itemName, item.qty))
                  else
                    Column(
                      children: [
                        _bogoRow('Buy', offer.buyItemName ?? 'Item', offer.buyQty, isMain: true),
                        12.verticalSpace,
                        Icon(Icons.add, color: AppColors.maroon.withValues(alpha: 0.3)),
                        12.verticalSpace,
                        _bogoRow('Get FREE', offer.getItemName ?? 'Item', offer.getQty, isReward: true),
                      ],
                    ),

                  32.verticalSpace,

                  // Action Row
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Offer Price', style: TextStyle(fontSize: 12.sp, color: AppColors.textDark.withValues(alpha: 0.5))),
                          Text(
                            offer.type == OfferType.combo 
                                ? '₹${offer.comboPrice.toStringAsFixed(0)}' 
                                : _buyItem != null ? '₹${(_buyItem!.effectivePrice * offer.buyQty).toStringAsFixed(0)}' : '---',
                            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w900, color: AppColors.maroon),
                          ),
                        ],
                      ),
                      24.horizontalSpace,
                      Expanded(
                        child: SizedBox(
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: _loadingItems ? null : () {
                              context.read<CartProvider>().addOffer(offer, buyItem: _buyItem, getItem: _getItem);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Offer added to cart!')),
                              );
                            },
                            child: const Text('ADD TO CART'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(OfferType type) {
    final isCombo = type == OfferType.combo;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: (isCombo ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        isCombo ? 'COMBO' : 'SPECIAL',
        style: TextStyle(
          fontSize: 10.sp, 
          fontWeight: FontWeight.w900, 
          color: isCombo ? Colors.blue.shade800 : Colors.orange.shade800,
        ),
      ),
    );
  }

  Widget _itemRow(String name, int qty) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18.r, color: AppColors.success),
          12.horizontalSpace,
          Expanded(child: Text(name, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500))),
          Text('x$qty', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.maroon)),
        ],
      ),
    );
  }

  Widget _bogoRow(String prefix, String name, int qty, {bool isMain = false, bool isReward = false}) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isReward ? AppColors.success.withValues(alpha: 0.05) : AppColors.cream,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isReward ? AppColors.success.withValues(alpha: 0.1) : AppColors.maroon.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Text(prefix, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isReward ? AppColors.success : AppColors.textDark)),
          12.horizontalSpace,
          Expanded(child: Text(name, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600))),
          Text('x$qty', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
