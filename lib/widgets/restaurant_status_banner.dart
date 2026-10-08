import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../models/restaurant_settings.dart';
import '../providers/restaurant_provider.dart';
import '../theme/app_theme.dart';

class RestaurantStatusBanner extends StatelessWidget {
  final RestaurantSettings? settings;

  const RestaurantStatusBanner({super.key, this.settings});

  @override
  Widget build(BuildContext context) {
    if (settings != null) {
      return _buildContent(settings!);
    }

    final provider = context.watch<RestaurantProvider>();
    return _buildContent(provider.settings, provider: provider);
  }

  Widget _buildContent(RestaurantSettings activeSettings,
      {RestaurantProvider? provider}) {
    final isAccepting = provider?.isAcceptingOrders ??
        _computeIsAccepting(activeSettings);

    // Do NOT show any banner if the restaurant is OPEN and accepting orders
    if (isAccepting) {
      return const SizedBox.shrink();
    }

    final message = provider?.statusMessage ?? _computeMessage(activeSettings);
    final isPaused = activeSettings.pause.isActive;

    final IconData icon = isPaused
        ? Icons.pause_circle_filled_rounded
        : Icons.highlight_off_rounded;

    const Color color = AppColors.error;

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

  bool _computeIsAccepting(RestaurantSettings s) {
    if (!s.isOpen || !s.delivery.enabled || s.pause.isActive) return false;
    return true;
  }

  String _computeMessage(RestaurantSettings s) {
    if (!s.isOpen) return '🔴 Closed — Not accepting orders';
    if (!s.delivery.enabled) return '🔴 Delivery is currently disabled';
    if (s.pause.isActive) {
      final reason =
          s.pause.reason.isNotEmpty ? ' (${s.pause.reason})' : '';
      return '⏸ Temporarily unavailable$reason';
    }
    return '';
  }
}
