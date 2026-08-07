import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'edit_profile_screen.dart';
import 'saved_addresses_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(title: const Text('My Account')),
      body: StreamBuilder<AppUser?>(
        stream: authService.watchUser(user.uid),
        builder: (context, snapshot) {
          final appUser = snapshot.data;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 32.h),
                  decoration: BoxDecoration(
                    color: AppColors.maroon,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32.r)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40.r,
                        backgroundColor: AppColors.gold,
                        child: Text(
                          (appUser?.name.isNotEmpty == true) ? appUser!.name[0].toUpperCase() : 'U',
                          style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: AppColors.maroon),
                        ),
                      ),
                      16.verticalSpace,
                      Text(
                        appUser?.name ?? 'User',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: AppColors.white),
                      ),
                      4.verticalSpace,
                      Text(
                        appUser?.phone ?? '',
                        style: TextStyle(color: AppColors.gold.withValues(alpha: 0.8), fontSize: 13.sp),
                      ),
                    ],
                  ),
                ),
                
                24.verticalSpace,
                
                // Menu Items
                _AccountMenuItem(
                  icon: Icons.person_outline,
                  label: 'Edit Profile',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
                _AccountMenuItem(
                  icon: Icons.location_on_outlined,
                  label: 'Saved Addresses',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen())),
                ),
                _AccountMenuItem(
                  icon: Icons.info_outline,
                  label: 'About App',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Maruthi Eats',
                      applicationVersion: '1.0.0',
                      applicationIcon: Icon(Icons.restaurant_menu, color: AppColors.maroon, size: 40.r),
                    );
                  },
                ),
                
                32.verticalSpace,
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: OutlinedButton.icon(
                      onPressed: () => authService.signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                    ),
                  ),
                ),
                
                24.verticalSpace,
                Text(
                  'v1.0.0',
                  style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.3), fontSize: 12.sp),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AccountMenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: AppColors.maroon.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: AppColors.maroon, size: 24.r),
      ),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
      trailing: Icon(Icons.chevron_right, color: AppColors.grey.withValues(alpha: 0.4), size: 20.r),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 4.h),
    );
  }
}
