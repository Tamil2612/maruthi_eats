import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/cart_fab.dart';

class FullMenuScreen extends StatefulWidget {
  final String? initialCategory;
  const FullMenuScreen({super.key, this.initialCategory});

  @override
  State<FullMenuScreen> createState() => _FullMenuScreenState();
}

class _FullMenuScreenState extends State<FullMenuScreen> {
  late String _selectedCategory;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, GlobalKey> _categoryKeys = {};

  String _searchQuery = '';
  bool? _vegFilter; // null = all, true = veg, false = non-veg

  bool _isCollapsed = false;

  late final Stream<QuerySnapshot> _categoriesStream =
  FirebaseFirestore.instance.collection('categories').orderBy('order').snapshots();
  late final Stream<QuerySnapshot> _menuItemsStream =
  FirebaseFirestore.instance.collection('menu_items').snapshots();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });

    _scrollController.addListener(() {
      final collapsed = _scrollController.hasClients && 
                        _scrollController.offset > (90.h - kToolbarHeight - MediaQuery.of(context).padding.top - 10);
      if (collapsed != _isCollapsed) {
        setState(() => _isCollapsed = collapsed);
      }
    });

    // Initial scroll to category if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedCategory != 'All') {
        _scrollChipIntoView(_selectedCategory);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollChipIntoView(String category) {
    Future.delayed(const Duration(milliseconds: 100), () {
      final key = _categoryKeys[category];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.3, // Brings the item into view with space on the right
        );
      }
    });
  }

  void _selectCategory(String category) {
    if (category == _selectedCategory) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedCategory = category);
    _scrollChipIntoView(category);
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _categoriesStream,
            builder: (context, catSnapshot) {
              final categories = ['All'];
              if (catSnapshot.hasData) {
                for (var doc in catSnapshot.data!.docs) {
                  final name = (doc.data() as Map<String, dynamic>)['name'] as String?;
                  if (name != null && !categories.contains(name)) categories.add(name);
                }
              }

              return StreamBuilder<QuerySnapshot>(
                stream: _menuItemsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const _ErrorState();
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.maroon));
                  }

                  final allItems = snapshot.data!.docs
                      .map((doc) => MenuItem.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
                      .toList();

                  final cartProvider = context.read<CartProvider>();
                  for (var item in allItems) {
                    cartProvider.syncMenuItem(item);
                  }

                  if (allItems.isEmpty) return const _EmptyMenuState();

                  final filteredItems = allItems.where((item) {
                    final matchesSearch = item.name.toLowerCase().contains(_searchQuery) ||
                        item.description.toLowerCase().contains(_searchQuery);
                    final matchesDiet = _vegFilter == null || item.isVeg == _vegFilter;
                    final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
                    return matchesSearch && matchesDiet && matchesCategory;
                  }).toList();

                  // Group by category (only matters in "All" view — a
                  // specific category selection naturally yields one group)
                  final Map<String, List<MenuItem>> groupedItems = {};
                  for (var cat in categories.where((c) => c != 'All')) {
                    final items = filteredItems.where((i) => i.category == cat).toList();
                    if (items.isNotEmpty) groupedItems[cat] = items;
                  }

                  final categoryCounts = <String, int>{
                    for (final cat in categories.where((c) => c != 'All'))
                      cat: allItems.where((i) => i.category == cat).length,
                  };

                  return CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildAppBar(),
                      SliverToBoxAdapter(child: _buildSearchAndFilters()),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyHeaderDelegate(
                          height: 58.h,
                          child: _buildCategoryBar(categories, categoryCounts),
                        ),
                      ),
                      if (groupedItems.isEmpty)
                        SliverFillRemaining(child: _buildNoResultsState())
                      else
                        ...groupedItems.entries.map((entry) => SliverMainAxisGroup(
                          slivers: [
                            if (_selectedCategory == 'All') SliverToBoxAdapter(child: _sectionHeader(entry.key, entry.value.length)),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                    (context, index) => MenuItemCard(item: entry.value[index]),
                                childCount: entry.value.length,
                              ),
                            ),
                          ],
                        )),
                      SliverToBoxAdapter(child: 140.verticalSpace),
                    ],
                  );
                },
              );
            },
          ),
          const CartFab(bottom: 20),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: AppColors.maroon,
      surfaceTintColor: AppColors.maroon,
      iconTheme: const IconThemeData(color: AppColors.gold, size: 20),
      expandedHeight: 90.h,
      automaticallyImplyLeading: false,
      leading: _isCollapsed
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      centerTitle: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(
          left: _isCollapsed ? 56.w : 16.w, 
          bottom: 16.h
        ),
        title: Text(
          'MARUTHI EATS',
          style: AppTheme.logoStyle.copyWith(fontSize: 16.sp),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.maroon, AppColors.maroonDark],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 16.w, bottom: 42.h),
              child: Text(
                'FULL MENU',
                style: TextStyle(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for favorite dishes...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.sp),
              prefixIcon: const Icon(Icons.search, color: AppColors.maroon, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                onPressed: _searchController.clear,
              )
                  : null,
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: AppColors.maroon.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: AppColors.maroon.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: AppColors.maroon.withValues(alpha: 0.4), width: 1.4),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
            ),
          ),
          14.verticalSpace,
          Row(
            children: [
              _FilterPill(
                label: 'Veg',
                isSelected: _vegFilter == true,
                color: AppColors.success,
                onTap: () => setState(() => _vegFilter = (_vegFilter == true ? null : true)),
              ),
              10.horizontalSpace,
              _FilterPill(
                label: 'Non-Veg',
                isSelected: _vegFilter == false,
                color: AppColors.error,
                onTap: () => setState(() => _vegFilter = (_vegFilter == false ? null : false)),
              ),
              const Spacer(),
              if (_vegFilter != null || _searchQuery.isNotEmpty || _selectedCategory != 'All')
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _vegFilter = null;
                      _selectedCategory = 'All';
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear all',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.maroon.withValues(alpha: 0.6)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(List<String> categories, Map<String, int> categoryCounts) {
    return Container(
      color: AppColors.cream,
      height: 58.h,
      alignment: Alignment.center,
      child: ListView.builder(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          _categoryKeys.putIfAbsent(cat, () => GlobalKey());

          final isSelected = _selectedCategory == cat;
          final count = cat == 'All' ? null : categoryCounts[cat];
          return Padding(
            key: _categoryKeys[cat],
            padding: EdgeInsets.only(right: 8.w),
            child: Center(
              child: GestureDetector(
                onTap: () => _selectCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.maroon : AppColors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: isSelected ? AppColors.maroon : AppColors.maroon.withValues(alpha: 0.12)),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.maroon.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? AppColors.gold : AppColors.maroon,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12.sp,
                        ),
                      ),
                      if (count != null) ...[
                        6.horizontalSpace,
                        Text(
                          '$count',
                          style: TextStyle(
                            color: isSelected ? AppColors.gold.withValues(alpha: 0.7) : AppColors.maroon.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String category, int count) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 28.h, 16.w, 10.h),
      child: Row(
        children: [
          Text(
            category,
            style: GoogleFonts.playfairDisplay(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          8.horizontalSpace,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.maroon.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppColors.maroon),
            ),
          ),
          12.horizontalSpace,
          Expanded(child: Divider(color: AppColors.maroon.withValues(alpha: 0.08), thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_food_outlined, size: 60.r, color: Colors.grey.shade300),
            20.verticalSpace,
            Text(
              'Oops! No dishes found',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
            ),
            8.verticalSpace,
            Text(
              'Try a different search term, category, or filter.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5.sp, color: Colors.grey.shade500),
            ),
            16.verticalSpace,
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _vegFilter = null;
                  _selectedCategory = 'All';
                });
              },
              child: Text('Reset all filters', style: TextStyle(color: AppColors.maroon, fontWeight: FontWeight.w800, fontSize: 13.sp)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterPill({required this.label, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.white,
          border: Border.all(color: isSelected ? color : AppColors.maroon.withValues(alpha: 0.1), width: 1.w),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8.r,
              height: 8.r,
              decoration: BoxDecoration(color: isSelected ? AppColors.white : color, shape: BoxShape.circle),
            ),
            10.horizontalSpace,
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.textDark.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        boxShadow: [
          if (shrinkOffset > 0) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}

class _EmptyMenuState extends StatelessWidget {
  const _EmptyMenuState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 64.r, color: Colors.grey.shade200),
          16.verticalSpace,
          const Text('Coming soon...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Error loading menu'));
}