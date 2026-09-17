import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';


class ProfileSetupScreen extends StatefulWidget {
  final String phoneNumber;
  const ProfileSetupScreen({super.key, required this.phoneNumber});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _authService = AuthService();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: AppColors.textDark),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.maroon,
              onPrimary: AppColors.gold,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Almost there')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Complete Your Profile",
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w700, color: AppColors.maroon),
            ),
            8.verticalSpace,
            Text(
              "Help us serve you better by providing these details.",
              style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.6), fontSize: 14.sp),
            ),
            32.verticalSpace,

            _buildFieldLabel("Full Name"),
            8.verticalSpace,
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. John Doe',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            24.verticalSpace,

            _buildFieldLabel("Email Address"),
            8.verticalSpace,
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'john@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            24.verticalSpace,

            _buildFieldLabel("Date of Birth"),
            8.verticalSpace,
            TextField(
              controller: _dobController,
              readOnly: true,
              onTap: _selectDate,
              decoration: const InputDecoration(
                hintText: 'Select your birth date',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
            ),

            if (_error != null) ...[
              16.verticalSpace,
              Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 16.r),
                  8.horizontalSpace,
                  Expanded(child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13.sp))),
                ],
              ),
            ],
            32.verticalSpace,
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.maroon,
                  foregroundColor: AppColors.gold,
                ),
                child: _saving
                    ? SizedBox(
                        height: 20.h, width: 20.w,
                        child: CircularProgressIndicator(strokeWidth: 2.w, color: AppColors.gold))
                    : const Text('Create Profile'),
              ),
            ),
            24.verticalSpace,
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final dob = _dobController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }
    if (dob.isEmpty) {
      setState(() => _error = 'Please select your date of birth');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final uid = _authService.currentUser!.uid;
      await _authService.saveProfile(
        uid: uid,
        name: name,
        phone: widget.phoneNumber,
        email: email,
        dob: dob,
      );

      // AuthGate will detect the profile update and switch to HomeScreen.
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Could not save your details. Please try again.';
      });
    }
  }
}
