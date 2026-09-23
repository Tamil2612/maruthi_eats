import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'order_history_screen.dart';
import 'account_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cart_fab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  StreamSubscription<String>? _tokenRefreshSubscription;

  final List<Widget> _screens = [
    const HomeScreen(),
    const OrderHistoryScreen(),
    const AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Registers this device for order-status push notifications — see
    // AuthService.saveFcmToken and backend/functions/main.py's
    // on_order_status_updated. Runs once per app session, right when the
    // user is confirmed signed in with a completed profile (AuthGate only
    // shows this screen at that point).
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final authService = AuthService();
      authService.saveFcmToken(uid);
      _tokenRefreshSubscription = authService.listenForTokenRefresh(uid);
    }
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: userId == null
          ? null
          : FirebaseFirestore.instance
          .collection('orders')
          .where('customer_id', isEqualTo: userId)
          .where('order_status', whereIn: [
        'placed',
        'preparing',
        'out_for_delivery'
      ]).snapshots(),
      builder: (context, snapshot) {
        final hasLiveOrders =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

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
            items: [
              BottomNavigationBarItem(
                icon: _buildIcon('assets/icons/home.png', false),
                activeIcon: _buildIcon('assets/icons/home.png', true),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon('assets/icons/orders.png', false),
                activeIcon: _buildIcon('assets/icons/orders.png', true),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon('assets/icons/profile.png', false),
                activeIcon: _buildIcon('assets/icons/profile.png', true),
                label: 'Account',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIcon(String path, bool active) {
    return Container(
      width: 24.w,
      height: 24.w,
      alignment: Alignment.center,
      margin: EdgeInsets.only(bottom: 2.h),
      child: Image.asset(
        path,
        width: 22.w,
        height: 22.w,
        fit: BoxFit.contain,
        color: active ? AppColors.maroon : AppColors.textDark.withValues(alpha: 0.4),
      ),
    );
  }
}