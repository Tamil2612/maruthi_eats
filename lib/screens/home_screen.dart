import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/app_drawer.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('MARUTHI EATS'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Falls back gracefully until Firestore + menu data are set up
        stream: FirebaseFirestore.instance
            .collection('menu_items')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _ErrorState();
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.maroon),
            );
          }

          final allItems = snapshot.data!.docs
              .map((doc) => MenuItem.fromFirestore(
                  doc.id, doc.data() as Map<String, dynamic>))
              .toList();

          if (allItems.isEmpty) {
            return const _EmptyMenuState();
          }

          final categories = ['All', ...{for (var i in allItems) i.category}];
          final filtered = _selectedCategory == 'All'
              ? allItems
              : allItems.where((i) => i.category == _selectedCategory).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: categories.map((cat) {
                    final selected = cat == _selectedCategory;
                    return Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                        selectedColor: AppColors.maroon,
                        backgroundColor: AppColors.white,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: selected ? AppColors.gold : AppColors.maroon,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13.sp,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Section Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Text(
                  _selectedCategory == 'All' ? 'Popular Items' : _selectedCategory,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
                ),
              ),
              // Menu list
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(bottom: 100.h),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => MenuItemCard(item: filtered[i]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
              label: Text('View Cart (${cart.itemCount}) · ₹${cart.subtotal.toStringAsFixed(0)}'),
              icon: const Icon(Icons.shopping_bag_outlined),
            ),
    );
  }
}

class _EmptyMenuState extends StatelessWidget {
  const _EmptyMenuState();

  Future<void> _seedData(BuildContext context) async {
    final items = [
      {
        'name': 'Paneer Tikka',
        'description': 'Spiced paneer cubes grilled to perfection with bell peppers.',
        'price': 250.0,
        'category': 'Starters',
        'image_url': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?auto=format&fit=crop&q=80&w=500',
        'is_veg': true,
        'available': true,
      },
      {
        'name': 'Butter Chicken',
        'description': 'Tender chicken in a creamy, buttery tomato-based gravy.',
        'price': 380.0,
        'category': 'Main Course',
        'image_url': 'https://images.unsplash.com/photo-1603894584134-f139fdec0f1b?auto=format&fit=crop&q=80&w=500',
        'is_veg': false,
        'available': true,
      },
      {
        'name': 'Garlic Naan',
        'description': 'Soft clay oven bread topped with minced garlic and butter.',
        'price': 60.0,
        'category': 'Breads',
        'image_url': 'https://images.unsplash.com/photo-1533777857889-4be7c70b33f7?auto=format&fit=crop&q=80&w=500',
        'is_veg': true,
        'available': true,
      },
      {
        'name': 'Hyderabadi Biryani',
        'description': 'Aromatic basmati rice cooked with spices and choice of meat.',
        'price': 320.0,
        'category': 'Main Course',
        'image_url': 'https://images.unsplash.com/photo-1563379091339-03b21bc4a4f8?auto=format&fit=crop&q=80&w=500',
        'is_veg': false,
        'available': true,
      },
      {
        'name': 'Mango Lassi',
        'description': 'Classic Indian yogurt drink blended with sweet mangoes.',
        'price': 120.0,
        'category': 'Beverages',
        'image_url': 'https://images.unsplash.com/photo-1546173159-315724a93c90?auto=format&fit=crop&q=80&w=500',
        'is_veg': true,
        'available': true,
      },
      {
        'name': 'Gulab Jamun',
        'description': 'Golden milk-solid dumplings soaked in saffron syrup.',
        'price': 90.0,
        'category': 'Desserts',
        'image_url': 'https://images.unsplash.com/photo-1589119908995-c6837fa14848?auto=format&fit=crop&q=80&w=500',
        'is_veg': true,
        'available': true,
      },
    ];

    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance.collection('menu_items');

    for (var item in items) {
      batch.set(collection.doc(), item);
    }

    try {
      await batch.commit();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu seeded successfully!')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error seeding menu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 56.r, color: AppColors.maroon),
            16.verticalSpace,
            Text(
              'Menu coming soon',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            8.verticalSpace,
            Text(
              'No items in the "menu_items" Firestore collection yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.6), fontSize: 13.sp),
            ),
            24.verticalSpace,
            ElevatedButton.icon(
              onPressed: () => _seedData(context),
              icon: Icon(Icons.add_to_photos_outlined, size: 20.r),
              label: const Text('Seed Dummy Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56.r, color: AppColors.error),
            16.verticalSpace,
            const Text('Could not load the menu'),
            8.verticalSpace,
            Text(
              'Check your Firebase setup (firebase_options.dart) and internet connection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.6), fontSize: 13.sp),
            ),
          ],
        ),
      ),
    );
  }
}
