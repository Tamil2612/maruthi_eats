import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/address_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'add_edit_address_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      body: StreamBuilder<List<AddressModel>>(
        stream: _authService.watchAddresses(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48.r, color: AppColors.error),
                    16.verticalSpace,
                    Text('Permission Denied',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: AppColors.error)),
                    8.verticalSpace,
                    Text('Please update your Firestore rules in the Firebase Console.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.maroon));
          }

          final addresses = snapshot.data ?? [];

          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 64.r, color: AppColors.maroon.withValues(alpha: 0.3)),
                  16.verticalSpace,
                  Text('No addresses saved yet', style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.5))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
            itemCount: addresses.length,
            itemBuilder: (context, i) {
              final addr = addresses[i];
              return Container(
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.maroon.withValues(alpha: 0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.04),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.r),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Icon with soft background
                          Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: AppColors.maroon.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Icon(
                              addr.label.toLowerCase() == 'home'
                                  ? Icons.home_rounded
                                  : addr.label.toLowerCase() == 'work'
                                      ? Icons.business_rounded
                                      : Icons.place_rounded,
                              size: 26.r,
                              color: AppColors.maroon,
                            ),
                          ),
                          16.horizontalSpace,
                          // Address Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addr.label.toUpperCase(),
                                  style: TextStyle(
                                    color: AppColors.maroon,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11.sp,
                                    letterSpacing: 1.w,
                                  ),
                                ),
                                6.verticalSpace,
                                Text(
                                  addr.fullAddress,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.textDark.withValues(alpha: 0.7),
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                8.verticalSpace,
                                Row(
                                  children: [
                                    Icon(Icons.person_outline, size: 13.r, color: AppColors.textDark.withValues(alpha: 0.5)),
                                    4.horizontalSpace,
                                    Text(
                                      addr.recipientName,
                                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.textDark.withValues(alpha: 0.6)),
                                    ),
                                    12.horizontalSpace,
                                    Icon(Icons.phone_outlined, size: 13.r, color: AppColors.textDark.withValues(alpha: 0.5)),
                                    4.horizontalSpace,
                                    Text(
                                      addr.recipientPhone,
                                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.textDark.withValues(alpha: 0.6)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Action Buttons Row
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AddEditAddressScreen(address: addr)),
                            ),
                            icon: Icon(Icons.edit_outlined, size: 18.r),
                            label: const Text('EDIT'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.maroon,
                              textStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                          16.horizontalSpace,
                          TextButton.icon(
                            onPressed: () => _confirmDelete(addr),
                            icon: Icon(Icons.delete_outline, size: 18.r),
                            label: const Text('DELETE'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                              textStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20.r, offset: Offset(0, -10.h)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add New Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.maroon,
                foregroundColor: AppColors.gold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(AddressModel address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address?'),
        content: const Text('Are you sure you want to remove this address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _authService.deleteAddress(_authService.currentUser!.uid, address.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
