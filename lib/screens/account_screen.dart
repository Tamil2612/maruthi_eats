import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'edit_profile_screen.dart';
import 'saved_addresses_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

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
                
                24.verticalSpace,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Legal', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.textDark.withValues(alpha: 0.4), letterSpacing: 1)),
                  ),
                ),
                8.verticalSpace,
                
                _AccountMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                ),
                _AccountMenuItem(
                  icon: Icons.description_outlined,
                  label: 'Terms & Conditions',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsScreen())),
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
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: OutlinedButton.icon(
                          onPressed: () => _showSignOutDialog(context, authService),
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                        ),
                      ),
                      16.verticalSpace,
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => _showDeleteAccountDialog(context, authService),
                          child: Text(
                            'Delete Account',
                            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13.sp),
                          ),
                        ),
                      ),
                    ],
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

  void _showSignOutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              authService.signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: AppColors.maroon, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: AppColors.error)),
        content: const Text(
          'This action is permanent and cannot be undone. All your personal data, saved addresses, and order history will be deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await authService.deleteAccount();
                // Navigation to splash/login will be handled by the auth state stream in main.dart
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not delete account. You may need to log in again first.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete Permanently'),
          ),
        ],
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
