import 'package:cloud_firestore/cloud_firestore.dart';

class PauseSettings {
  final bool isPaused;
  final DateTime? pausedUntil;
  final String reason;

  PauseSettings({
    required this.isPaused,
    this.pausedUntil,
    this.reason = '',
  });

  factory PauseSettings.fromMap(Map<String, dynamic> map) {
    DateTime? until;
    if (map['paused_until'] is Timestamp) {
      until = (map['paused_until'] as Timestamp).toDate();
    } else if (map['paused_until'] is String) {
      until = DateTime.tryParse(map['paused_until']);
    }

    return PauseSettings(
      isPaused: map['is_paused'] ?? false,
      pausedUntil: until,
      reason: map['reason'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'is_paused': isPaused,
        'paused_until':
            pausedUntil != null ? Timestamp.fromDate(pausedUntil!) : null,
        'reason': reason,
      };

  bool get isActive {
    if (!isPaused) return false;
    if (pausedUntil == null) return true;
    return DateTime.now().isBefore(pausedUntil!);
  }
}

class DayOpeningHours {
  final bool enabled;
  final String open;
  final String close;

  DayOpeningHours({
    required this.enabled,
    required this.open,
    required this.close,
  });

  factory DayOpeningHours.fromMap(Map<String, dynamic> map) {
    return DayOpeningHours(
      enabled: map['enabled'] ?? true,
      open: map['open'] ?? '10:00',
      close: map['close'] ?? '22:30',
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'open': open,
        'close': close,
      };
}

class SpecialClosure {
  final String date; // YYYY-MM-DD
  final bool closed;
  final String reason;

  SpecialClosure({
    required this.date,
    required this.closed,
    required this.reason,
  });

  factory SpecialClosure.fromMap(Map<String, dynamic> map) {
    return SpecialClosure(
      date: map['date'] ?? '',
      closed: map['closed'] ?? true,
      reason: map['reason'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date,
        'closed': closed,
        'reason': reason,
      };
}

class DeliverySlab {
  final double upToKm;
  final double fee;

  DeliverySlab({required this.upToKm, required this.fee});

  factory DeliverySlab.fromMap(Map<String, dynamic> map) {
    return DeliverySlab(
      upToKm: (map['up_to_km'] ?? 0).toDouble(),
      fee: (map['fee'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'up_to_km': upToKm,
        'fee': fee,
      };
}

class DeliverySettings {
  final bool enabled;
  final double restaurantLatitude;
  final double restaurantLongitude;
  final double maxDeliveryDistanceKm;
  final List<DeliverySlab> slabs;

  DeliverySettings({
    required this.enabled,
    required this.restaurantLatitude,
    required this.restaurantLongitude,
    required this.maxDeliveryDistanceKm,
    required this.slabs,
  });

  factory DeliverySettings.fromMap(Map<String, dynamic> map) {
    final pricing = (map['pricing'] is Map)
        ? (map['pricing'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final rawSlabs = pricing['slabs'] as List? ?? [];

    return DeliverySettings(
      enabled: map['enabled'] ?? true,
      restaurantLatitude: (map['restaurant_latitude'] ?? 0.0).toDouble(),
      restaurantLongitude: (map['restaurant_longitude'] ?? 0.0).toDouble(),
      maxDeliveryDistanceKm:
          (map['max_delivery_distance_km'] ?? 8.0).toDouble(),
      slabs: rawSlabs
          .map((s) => DeliverySlab.fromMap(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'restaurant_latitude': restaurantLatitude,
        'restaurant_longitude': restaurantLongitude,
        'max_delivery_distance_km': maxDeliveryDistanceKm,
        'pricing': {
          'type': 'distance',
          'slabs': slabs.map((s) => s.toMap()).toList(),
        },
      };
}

class RestaurantSettings {
  final bool isOpen;
  final String timezone;
  final double minimumOrderValue;
  final PauseSettings pause;
  final Map<String, DayOpeningHours> openingHours;
  final List<SpecialClosure> specialClosures;
  final DeliverySettings delivery;

  RestaurantSettings({
    required this.isOpen,
    required this.timezone,
    required this.minimumOrderValue,
    required this.pause,
    required this.openingHours,
    required this.specialClosures,
    required this.delivery,
  });

  factory RestaurantSettings.fromFirestore(Map<String, dynamic> data) {
    final rawPause = (data['pause'] is Map)
        ? (data['pause'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final rawHours = (data['opening_hours'] is Map)
        ? (data['opening_hours'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final rawClosures = data['special_closures'] as List? ?? [];
    final rawDelivery = (data['delivery'] is Map)
        ? (data['delivery'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    final hoursMap = <String, DayOpeningHours>{};
    rawHours.forEach((key, val) {
      if (val is Map) {
        hoursMap[key.toLowerCase()] =
            DayOpeningHours.fromMap(val.cast<String, dynamic>());
      }
    });

    return RestaurantSettings(
      isOpen: data['is_open'] ?? true,
      timezone: data['timezone'] ?? 'Asia/Kolkata',
      minimumOrderValue: (data['minimum_order_value'] ?? 150.0).toDouble(),
      pause: PauseSettings.fromMap(rawPause),
      openingHours: hoursMap,
      specialClosures: rawClosures
          .map((c) => SpecialClosure.fromMap(c as Map<String, dynamic>))
          .toList(),
      delivery: DeliverySettings.fromMap(rawDelivery),
    );
  }

  static RestaurantSettings defaultSettings() {
    return RestaurantSettings(
      isOpen: true,
      timezone: 'Asia/Kolkata',
      minimumOrderValue: 150.0,
      pause: PauseSettings(isPaused: false, reason: ''),
      openingHours: {
        'monday': DayOpeningHours(enabled: true, open: '10:00', close: '22:30'),
        'tuesday':
            DayOpeningHours(enabled: true, open: '10:00', close: '22:30'),
        'wednesday':
            DayOpeningHours(enabled: true, open: '10:00', close: '22:30'),
        'thursday':
            DayOpeningHours(enabled: true, open: '10:00', close: '22:30'),
        'friday': DayOpeningHours(enabled: true, open: '10:00', close: '23:00'),
        'saturday':
            DayOpeningHours(enabled: true, open: '10:00', close: '23:00'),
        'sunday': DayOpeningHours(enabled: true, open: '10:00', close: '22:30'),
      },
      specialClosures: [],
      delivery: DeliverySettings(
        enabled: true,
        restaurantLatitude: 13.0827,
        restaurantLongitude: 80.2707,
        maxDeliveryDistanceKm: 8.0,
        slabs: [
          DeliverySlab(upToKm: 3.0, fee: 30.0),
          DeliverySlab(upToKm: 5.0, fee: 40.0),
          DeliverySlab(upToKm: 8.0, fee: 60.0),
        ],
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'is_open': isOpen,
        'timezone': timezone,
        'minimum_order_value': minimumOrderValue,
        'pause': pause.toMap(),
        'opening_hours': openingHours.map((k, v) => MapEntry(k, v.toMap())),
        'special_closures': specialClosures.map((c) => c.toMap()).toList(),
        'delivery': delivery.toMap(),
      };
}
