import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'auth/phone_login_screen.dart';
import 'auth/profile_setup_screen.dart';
import 'main_navigation_screen.dart';

/// Root router: shows login if signed out, profile setup if signed in but
/// registration isn't complete yet, otherwise the home/menu screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.cream,
            body: Center(child: CircularProgressIndicator(color: AppColors.maroon)),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const PhoneLoginScreen();
        }

        return StreamBuilder<bool>(
          stream: authService.watchProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 48.r),
                        16.verticalSpace,
                        Text('Could not load profile',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
                        8.verticalSpace,
                        Text(profileSnapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.5))),
                        24.verticalSpace,
                        ElevatedButton(
                          onPressed: () => authService.signOut(),
                          child: const Text('Sign Out & Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppColors.cream,
                body: Center(child: CircularProgressIndicator(color: AppColors.maroon)),
              );
            }

            if (profileSnapshot.data == true) {
              return const MainNavigationScreen();
            }
            return ProfileSetupScreen(phoneNumber: user.phoneNumber ?? '');
          },
        );
      },
    );
  }
}
