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
            padding: EdgeInsets.all(16.r),
            itemCount: addresses.length,
            itemBuilder: (context, i) {
              final addr = addresses[i];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.location_on_outlined, color: AppColors.maroon, size: 24.r),
                  title: Text(addr.label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  subtitle: Text(addr.fullAddress, style: TextStyle(fontSize: 13.sp, color: AppColors.textDark.withValues(alpha: 0.6))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_outlined, size: 20.r, color: Colors.blue),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddEditAddressScreen(address: addr)),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 20.r, color: AppColors.error),
                        onPressed: () => _confirmDelete(addr),
                      ),
                    ],
                  ),
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
