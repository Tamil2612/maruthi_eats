import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/restaurant_settings.dart';
import '../theme/app_theme.dart';

class RestaurantStatusBanner extends StatelessWidget {
  final RestaurantSettings settings;

  const RestaurantStatusBanner({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // 1. Manual switch check
    if (!settings.isOpen) {
      return _buildBanner(
        icon: Icons.highlight_off_rounded,
        color: AppColors.error,
        message: '🔴 Closed — Not accepting orders',
      );
    }

    // 2. Delivery check
    if (!settings.delivery.enabled) {
      return _buildBanner(
        icon: Icons.no_food_outlined,
        color: AppColors.error,
        message: '🔴 Delivery is currently disabled',
      );
    }

    // 3. Pause check
    if (settings.pause.isActive) {
      final reason = settings.pause.reason.isNotEmpty
          ? ' (${settings.pause.reason})'
          : '';
      return _buildBanner(
        icon: Icons.pause_circle_filled_rounded,
        color: AppColors.error,
        message: '⏸ Temporarily unavailable$reason',
      );
    }

    // 4. Special Closure check
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    for (var sc in settings.specialClosures) {
      if (sc.date == dateStr && sc.closed) {
        final reason = sc.reason.isNotEmpty ? ' — ${sc.reason}' : '';
        return _buildBanner(
          icon: Icons.event_busy_rounded,
          color: AppColors.error,
          message: '🔴 Closed today$reason',
        );
      }
    }

    // 5. Opening Hours check
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final dayName = days[now.weekday - 1];
    final dayHours = settings.openingHours[dayName];

    if (dayHours != null) {
      if (!dayHours.enabled) {
        return _buildBanner(
          icon: Icons.access_time_rounded,
          color: AppColors.error,
          message: '🔴 Closed today',
        );
      }

      final openMins = _parseMins(dayHours.open);
      final closeMins = _parseMins(dayHours.close);
      final nowMins = now.hour * 60 + now.minute;

      final bool isOpen = openMins > closeMins
          ? (nowMins >= openMins || nowMins < closeMins)
          : (nowMins >= openMins && nowMins < closeMins);

      if (!isOpen) {
        final open12h = _format12h(dayHours.open);
        return _buildBanner(
          icon: Icons.access_time_rounded,
          color: AppColors.error,
          message: '🔴 Closed — Opens at $open12h',
        );
      }
    }

    // Open & accepting orders
    return _buildBanner(
      icon: Icons.check_circle_rounded,
      color: AppColors.success,
      message: '🟢 Open — Accepting orders',
    );
  }

  int _parseMins(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (_) {
      return 600;
    }
  }

  String _format12h(String timeStr) {
    try {
      final mins = _parseMins(timeStr);
      final h = mins ~/ 60;
      final m = mins % 60;
      final suffix = h < 12 ? 'AM' : 'PM';
      final h12 = (h % 12 == 0) ? 12 : h % 12;
      return '$h12:${m.toString().padLeft(2, '0')} $suffix';
    } catch (_) {
      return timeStr;
    }
  }

  Widget _buildBanner({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18.r),
          10.horizontalSpace,
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
