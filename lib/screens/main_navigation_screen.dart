import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'order_history_screen.dart';
import 'account_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/cart_fab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const OrderHistoryScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: userId == null 
        ? null 
        : FirebaseFirestore.instance
            .collection('orders')
            .where('customer_id', isEqualTo: userId)
            .where('order_status', whereIn: ['placed', 'confirmed', 'preparing', 'out_for_delivery'])
            .snapshots(),
      builder: (context, snapshot) {
        final hasLiveOrders = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Scaffold(
          body: Stack(
            children: [
              IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
              
              // Global Cart FAB - Adjusts height if there are live orders on Home screen
              CartFab(
                bottom: (_currentIndex == 0 && hasLiveOrders) ? 100.h : 16.h,
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: AppColors.white,
            iconSize: 20.r,
            selectedFontSize: 10.sp,
            unselectedFontSize: 10.sp,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined),
                activeIcon: Icon(Icons.shopping_bag),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Account',
              ),
            ],
          ),
        );
      },
    );
  }
}
