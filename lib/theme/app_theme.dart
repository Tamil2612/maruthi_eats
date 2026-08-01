import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

/// Maruthi Eats brand colors
class AppColors {
  static const Color maroon = Color(0xFF800020);
  static const Color gold = Color(0xFFD4AF37);
  static const Color cream = Color(0xFFFFF8E7);
  static const Color textDark = Color(0xFF333333);
  static const Color white = Color(0xFFFFFFFF);

  // Derived shades for states/depth
  static const Color maroonDark = Color(0xFF5C0017);
  static const Color goldLight = Color(0xFFE8CC6B);
  static const Color success = Color(0xFF3A7D44);
  static const Color error = Color(0xFFB00020);
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      primaryColor: AppColors.maroon,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.maroon,
        primary: AppColors.maroon,
        secondary: AppColors.gold,
        surface: AppColors.white,
        error: AppColors.error,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),

      // App bar: Maroon background, gold/white text
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.maroon,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: AppColors.white,
          fontSize: 22.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.gold),
      ),

      // Primary buttons: Gold with dark text (per brand spec)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.textDark,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.maroon,
          side: const BorderSide(color: AppColors.maroon, width: 1.5),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: AppColors.maroon.withValues(alpha: 0.05)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.maroon,
        labelStyle: GoogleFonts.poppins(
          color: AppColors.maroon,
          fontWeight: FontWeight.w500,
          fontSize: 13.sp,
        ),
        secondaryLabelStyle: GoogleFonts.poppins(
          color: AppColors.gold,
          fontWeight: FontWeight.w600,
          fontSize: 13.sp,
        ),
        side: BorderSide(color: AppColors.maroon.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.textDark,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.maroon,
        unselectedItemColor: AppColors.textDark.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.maroon.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.maroon.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.maroon, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.textDark.withValues(alpha: 0.08),
        thickness: 1,
      ),
    );
  }

  /// Display font for the logo/hero moments (Gold on Maroon)
  static TextStyle get logoStyle => GoogleFonts.playfairDisplay(
        color: AppColors.gold,
        fontSize: 28.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      );
}
