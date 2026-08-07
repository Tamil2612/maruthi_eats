import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/live_order_tracker.dart';
import 'full_menu_screen.dart';

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
                      icon: const Icon(Icons.restaurant_menu),
                      label: Text('VIEW ALL MENU', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.maroon,
                        foregroundColor: AppColors.gold,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r)),
                      ),
                    ),
                  ),
                ),
                140.verticalSpace, // Extra space for floating elements
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
    final banners = [
      'assets/banners/banner_one.png',
      'assets/banners/banner_two.png',
      'assets/banners/banner_three.png',
    ];

    return CarouselSlider(
      options: CarouselOptions(
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.95,
        aspectRatio: 2.0,
        // Taller aspect ratio for a bigger banner
        autoPlayInterval: const Duration(seconds: 5),
      ),
      items: banners.map((assetPath) {
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
              padding: EdgeInsets.all(4.r), // Spacing between border and image
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.asset(
                  assetPath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        );
      }).toList(),
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
                        image: image.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(image),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: image.isEmpty
                          ? const Center(
                              child:
                                  Icon(Icons.fastfood, color: AppColors.maroon))
                          : null,
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
}
