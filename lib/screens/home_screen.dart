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
import 'offers_list_screen.dart';
import '../models/offer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MARUTHI EATS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
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

                24.verticalSpace,
                // Special Offers Section
                _buildSpecialOffersSection(context),

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
      stream: FirebaseFirestore.instance.collection('banners').snapshots(),
      builder: (context, snapshot) {
        // Fallback to local banners if Firestore is loading or empty
        List<dynamic> bannerData = [
          {'type': 'local', 'path': 'assets/banners/banner_one.png'},
          {'type': 'local', 'path': 'assets/banners/banner_two.png'},
          {'type': 'local', 'path': 'assets/banners/banner_three.png'},
        ];

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          bannerData = snapshot.data!.docs.map((doc) => {'type': 'network', 'url': doc['image_url']}).toList();
        }

        return CarouselSlider(
          options: CarouselOptions(
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.95,
            aspectRatio: 2.0,
            autoPlayInterval: const Duration(seconds: 5),
          ),
          items: bannerData.map((data) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
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
                            data['path'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            imageUrl: data['url'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>  ShimmerLoader(child: Container(color: Colors.white)),
                            errorWidget: (context, url, error) => Image.asset('assets/icons/placeholder_food.png', fit: BoxFit.cover),
                          ),
                  ),
                );
              },
            );
          }).toList(),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.maroon));
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
                                placeholder: (context, url) => const CategorySkeleton(),
                                errorWidget: (context, url, error) => Image.asset(
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

  Widget _buildSpecialOffersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Special Offers',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.maroon),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OffersListScreen()),
                ),
                child: Text('See All', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13.sp)),
              ),
            ],
          ),
        ),
        8.verticalSpace,
        SizedBox(
          height: 140.h,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('offers')
                .where('is_active', isEqualTo: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final offers = snapshot.data!.docs
                  .map((doc) => OfferModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
                  .toList();

              if (offers.isEmpty) return const SizedBox.shrink();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  return GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => OfferDetailsSheet(offer: offer),
                    ),
                    child: Container(
                      width: 260.w,
                      margin: EdgeInsets.only(right: 12.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.maroon.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          if (offer.imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(16.r)),
                              child: CachedNetworkImage(
                                imageUrl: offer.imageUrl,
                                width: 90.w,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(12.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    offer.title,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  4.verticalSpace,
                                  Text(
                                    offer.description,
                                    style: TextStyle(fontSize: 11.sp, color: AppColors.textDark.withValues(alpha: 0.6)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  8.verticalSpace,
                                  Text(
                                    offer.type == OfferType.combo 
                                      ? '₹${offer.comboPrice.toStringAsFixed(0)}'
                                      : 'FREE REWARD',
                                    style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.maroon, fontSize: 14.sp),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
