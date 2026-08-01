import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../screens/order_history_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/saved_addresses_screen.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) return const Drawer();

    return Drawer(
      backgroundColor: AppColors.cream,
      child: StreamBuilder<AppUser?>(
        stream: authService.watchUser(user.uid),
        builder: (context, snapshot) {
          final appUser = snapshot.data;

          return Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: AppColors.maroon),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: AppColors.gold,
                  child: Text(
                    (appUser?.name.isNotEmpty == true) ? appUser!.name[0].toUpperCase() : 'U',
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AppColors.maroon),
                  ),
                ),
                accountName: Text(
                  appUser?.name ?? 'User',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
                ),
                accountEmail: Text(
                  appUser?.phone ?? '',
                  style: TextStyle(color: AppColors.gold.withValues(alpha: 0.8), fontSize: 13.sp),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _DrawerItem(
                      icon: Icons.home_outlined,
                      label: 'Home',
                      onTap: () => Navigator.pop(context),
                    ),
                    _DrawerItem(
                      icon: Icons.history,
                      label: 'Order History',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.person_outline,
                      label: 'Edit Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.location_on_outlined,
                      label: 'Saved Addresses',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen()));
                      },
                    ),
                    const Divider(),
                    _DrawerItem(
                      icon: Icons.logout,
                      label: 'Sign Out',
                      onTap: () {
                        Navigator.pop(context);
                        authService.signOut();
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Text(
                  'v1.0.0',
                  style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.3), fontSize: 12.sp),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.maroon, size: 24.r),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp)),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w),
    );
  }
}
