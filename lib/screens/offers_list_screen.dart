import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/offer.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/offer_details_sheet.dart';

class OffersListScreen extends StatelessWidget {
  const OffersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Special Offers & Combos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('offers')
            .where('is_active', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading offers'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.maroon));

          final offers = snapshot.data!.docs
              .map((doc) => OfferModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
              .toList();

          if (offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stars_outlined, size: 64.r, color: AppColors.gold.withValues(alpha: 0.3)),
                  16.verticalSpace,
                  const Text('No special offers at the moment', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(16.r),
            itemCount: offers.length,
            separatorBuilder: (_, __) => 16.verticalSpace,
            itemBuilder: (context, i) => _OfferCard(offer: offers[i]),
          );
        },
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final OfferModel offer;
  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (offer.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              child: CachedNetworkImage(
                imageUrl: offer.imageUrl,
                height: 160.h,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) =>  ShimmerLoader(child: Container(color: Colors.white)),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        offer.title,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.sp),
                      ),
                    ),
                    _TypeBadge(type: offer.type),
                  ],
                ),
                8.verticalSpace,
                Text(
                  offer.description,
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textDark.withValues(alpha: 0.6), height: 1.4),
                ),
                16.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (offer.type == OfferType.combo)
                      Text(
                        '₹${offer.comboPrice.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.maroon, fontSize: 18.sp),
                      )
                    else
                      Text(
                        'Buy ${offer.buyQty} Get ${offer.getQty} FREE',
                        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.maroon, fontSize: 14.sp),
                      ),
                    ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => OfferDetailsSheet(offer: offer),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.maroon,
                        foregroundColor: AppColors.gold,
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: const Text('VIEW OFFER'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final OfferType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isCombo = type == OfferType.combo;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: (isCombo ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        isCombo ? 'COMBO' : 'SPECIAL',
        style: TextStyle(
          fontSize: 9.sp, 
          fontWeight: FontWeight.w900, 
          color: isCombo ? Colors.blue.shade800 : Colors.orange.shade800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
