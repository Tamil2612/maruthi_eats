import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/live_order_tracker.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/offer_details_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'full_menu_screen.dart';
import '../models/offer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<QuerySnapshot> _bannersStream;
  late Stream<QuerySnapshot> _offersStream;

  @override
  void initState() {
    super.initState();
    _bannersStream = FirebaseFirestore.instance.collection('banners').snapshots();
    _offersStream = FirebaseFirestore.instance.collection('offers').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MARUTHI EATS'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                16.verticalSpace,
                // Banner Carousel
                _buildBannerCarousel(),

                24.verticalSpace,
                // Categories Title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'Explore Categories',
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.maroon),
                  ),
                ),
                16.verticalSpace,

                // Categories Grid
                _buildCategoriesGrid(context),

                32.verticalSpace,
                // View All Menu Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FullMenuScreen()),
                      ),
                      icon: Image.asset(
                        "assets/icons/menu.png",
                        width: 28.w,
                        height: 28.h,
                        color: AppColors.gold,
                      ),
                      label: Text('VIEW ALL MENU',
                          style: TextStyle(
                              fontSize: 14.sp, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.maroon,
                        foregroundColor: AppColors.gold,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r)),
                      ),
                    ),
                  ),
                ),
                140.verticalSpace,
              ],
            ),
          ),
          Positioned(
            bottom: 6.h,
            left: 0,
            right: 0,
            child: const LiveOrderTracker(),
          ),
        ],
      ),
    );
  }


  Widget _buildBannerCarousel() {
    return StreamBuilder<QuerySnapshot>(
      stream: _bannersStream,
      builder: (context, bannerSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _offersStream,
          builder: (context, offerSnapshot) {
            // Show skeleton only on initial load when we have NO data from either stream
            final bool isInitialLoading = bannerSnapshot.connectionState == ConnectionState.waiting &&
                offerSnapshot.connectionState == ConnectionState.waiting;
            
            if (isInitialLoading) {
              return const BannerSkeleton();
            }

            List<Map<String, dynamic>> combinedData = [];

            // 1. Add Network Banners
            if (bannerSnapshot.hasData && bannerSnapshot.data!.docs.isNotEmpty) {
              combinedData.addAll(bannerSnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'item_type': 'banner',
                  'type': 'network',
                  'url': data['image_url'],
                  'is_coupon': data.containsKey('coupon_code') || data['type'] == 'coupon',
                  'data': data,
                };
              }));
            }

            // 2. Add Active Offers
            if (offerSnapshot.hasData && offerSnapshot.data!.docs.isNotEmpty) {
              final offers = offerSnapshot.data!.docs
                  .map((doc) => OfferModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
                  .where((o) => o.isActive) // Filter inactive in code to handle missing fields in DB
                  .where((o) => o.expiryDate == null || o.expiryDate!.isAfter(DateTime.now()))
                  .toList();

              combinedData.addAll(offers.map((offer) => {
                    'item_type': 'offer',
                    'type': 'network',
                    'url': offer.imageUrl,
                    'offer_model': offer,
                  }));
            }

            // 3. Fallback to local banners if NO network data is found after loading
            if (combinedData.isEmpty) {
              combinedData = [
                {'item_type': 'banner', 'type': 'local', 'path': 'assets/banners/banner_one.png', 'is_coupon': false},
                {'item_type': 'banner', 'type': 'local', 'path': 'assets/banners/banner_two.png', 'is_coupon': false},
                {'item_type': 'banner', 'type': 'local', 'path': 'assets/banners/banner_three.png', 'is_coupon': false},
              ];
            }

            return CarouselSlider(
              options: CarouselOptions(
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 0.95,
                aspectRatio: 2.0,
                autoPlayInterval: const Duration(seconds: 5),
              ),
              items: combinedData.map((data) {
                return Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      onTap: () {
                        if (data['item_type'] == 'offer') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) =>
                                OfferDetailsSheet(offer: data['offer_model']),
                          );
                        } else if (data['item_type'] == 'banner') {
                          if (data['is_coupon'] == true) {
                            // "nothing should happen"
                            return;
                          }
                          // Other banner actions could go here
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.maroon.withValues(alpha: 0.5),
                            width: 1.w,
                          ),
                        ),
                        padding: EdgeInsets.all(4.r),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: data['type'] == 'local'
                              ? Image.asset(
                                  data['path']!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : CachedNetworkImage(
                                  imageUrl: data['url']!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => ShimmerLoader(
                                      child: Container(color: Colors.white)),
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                          'assets/icons/placeholder_food.png',
                                          fit: BoxFit.cover),
                                ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading categories'));
        }

        // Use skeleton grid while loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.85,
            ),
            itemCount: 6,
            // Default 6 skeleton items
            itemBuilder: (context, index) => const CategorySkeleton(),
          );
        }

        final categoryDocs = snapshot.data?.docs ?? [];
        if (categoryDocs.isEmpty) {
          return const Center(child: Text('No categories found'));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.85,
          ),
          itemCount: categoryDocs.length,
          itemBuilder: (context, index) {
            final doc = categoryDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unnamed';
            final image = data['image_url'] ?? '';

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => FullMenuScreen(initialCategory: name)),
                );
              },
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: image,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const ShimmerLoader(
                                        child: SizedBox.expand()),
                                errorWidget: (context, url, error) =>
                                    Image.asset(
                                  'assets/icons/placeholder_food.png',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                'assets/icons/placeholder_food.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                  8.verticalSpace,
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
