import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/restaurant_settings.dart';
import '../services/restaurant_service.dart';

enum RestaurantStatusType {
  open,
  closed,
  paused,
}

class RestaurantProvider extends ChangeNotifier {
  final RestaurantService _service;
  StreamSubscription<RestaurantSettings>? _subscription;

  RestaurantSettings _settings = RestaurantSettings.defaultSettings();
  bool _isLoading = true;
  bool _hasError = false;

  RestaurantSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  RestaurantProvider({RestaurantService? service})
      : _service = service ?? RestaurantService() {
    _initStream();
  }

  void _initStream() {
    _subscription?.cancel();
    _subscription = _service.streamSettings().listen(
      (freshSettings) {
        _settings = freshSettings;
        _isLoading = false;
        _hasError = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming restaurant settings: $error');
        _hasError = true;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Explicitly updates settings for testing or manual overrides
  void updateSettings(RestaurantSettings newSettings) {
    _settings = newSettings;
    _isLoading = false;
    _hasError = false;
    notifyListeners();
  }

  /// Evaluates whether the restaurant is currently accepting orders.
  bool get isAcceptingOrders {
    if (_hasError) return false;
    if (!_settings.isOpen) return false;
    if (!_settings.delivery.enabled) return false;
    if (_settings.pause.isActive) return false;

    // Check special closures
    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    for (var sc in _settings.specialClosures) {
      if (sc.date == dateStr && sc.closed) {
        return false;
      }
    }

    // Check opening hours
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final dayName = days[now.weekday - 1];
    final dayHours = _settings.openingHours[dayName];

    if (dayHours != null) {
      if (!dayHours.enabled) return false;

      final openMins = _parseMins(dayHours.open);
      final closeMins = _parseMins(dayHours.close);
      final nowMins = now.hour * 60 + now.minute;

      final bool isOpenTime = openMins > closeMins
          ? (nowMins >= openMins || nowMins < closeMins)
          : (nowMins >= openMins && nowMins < closeMins);

      if (!isOpenTime) return false;
    }

    return true;
  }

  /// Returns the specific status category: open, closed, or paused.
  RestaurantStatusType get statusType {
    if (_settings.pause.isActive) {
      return RestaurantStatusType.paused;
    }
    if (!isAcceptingOrders) {
      return RestaurantStatusType.closed;
    }
    return RestaurantStatusType.open;
  }

  /// Human-readable status banner label
  String get statusMessage {
    final now = DateTime.now();

    if (!_settings.isOpen) {
      return '🔴 Closed — Not accepting orders';
    }

    if (!_settings.delivery.enabled) {
      return '🔴 Delivery is currently disabled';
    }

    if (_settings.pause.isActive) {
      final reason = _settings.pause.reason.isNotEmpty
          ? ' (${_settings.pause.reason})'
          : '';
      return '⏸ Temporarily unavailable$reason';
    }

    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    for (var sc in _settings.specialClosures) {
      if (sc.date == dateStr && sc.closed) {
        final reason = sc.reason.isNotEmpty ? ' — ${sc.reason}' : '';
        return '🔴 Closed today$reason';
      }
    }

    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final dayName = days[now.weekday - 1];
    final dayHours = _settings.openingHours[dayName];

    if (dayHours != null) {
      if (!dayHours.enabled) {
        return '🔴 Closed today';
      }

      final openMins = _parseMins(dayHours.open);
      final closeMins = _parseMins(dayHours.close);
      final nowMins = now.hour * 60 + now.minute;

      final bool isOpenTime = openMins > closeMins
          ? (nowMins >= openMins || nowMins < closeMins)
          : (nowMins >= openMins && nowMins < closeMins);

      if (!isOpenTime) {
        final open12h = _format12h(dayHours.open);
        return '🔴 Closed — Opens at $open12h';
      }
    }

    return '🟢 Open — Accepting orders';
  }

  /// Concise reason string for unavailable badges and buttons
  String get unavailableReason {
    if (_settings.pause.isActive) {
      return _settings.pause.reason.isNotEmpty
          ? 'Temporarily unavailable (${_settings.pause.reason})'
          : 'Temporarily unavailable';
    }
    if (!_settings.isOpen) {
      return 'Restaurant is closed';
    }
    if (!_settings.delivery.enabled) {
      return 'Delivery is disabled';
    }
    return 'Restaurant is currently closed';
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
