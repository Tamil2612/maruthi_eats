import 'package:flutter_test/flutter_test.dart';
import 'package:maruthi_eats/models/restaurant_settings.dart';

void main() {
  group('RestaurantSettings Model Tests', () {
    test('defaultSettings loads expected defaults', () {
      final settings = RestaurantSettings.defaultSettings();
      expect(settings.isOpen, isTrue);
      expect(settings.minimumOrderValue, equals(150.0));
      expect(settings.delivery.enabled, isTrue);
      expect(settings.delivery.maxDeliveryDistanceKm, equals(8.0));
      expect(settings.delivery.slabs.length, equals(3));
      expect(settings.delivery.slabs[0].upToKm, equals(3.0));
      expect(settings.delivery.slabs[0].fee, equals(30.0));
    });

    test('PauseSettings active check works', () {
      final activePause = PauseSettings(
        isPaused: true,
        pausedUntil: DateTime.now().add(const Duration(minutes: 30)),
        reason: 'Overloaded',
      );
      expect(activePause.isActive, isTrue);

      final expiredPause = PauseSettings(
        isPaused: true,
        pausedUntil: DateTime.now().subtract(const Duration(minutes: 5)),
        reason: 'Hold',
      );
      expect(expiredPause.isActive, isFalse);
    });

    test('fromFirestore parses full restaurant settings dict correctly', () {
      final map = {
        'is_open': false,
        'timezone': 'Asia/Kolkata',
        'minimum_order_value': 200,
        'pause': {
          'is_paused': true,
          'reason': 'Maintenance',
        },
        'opening_hours': {
          'monday': {'enabled': true, 'open': '09:00', 'close': '21:00'},
        },
        'special_closures': [
          {'date': '2026-10-20', 'closed': true, 'reason': 'Festival'}
        ],
        'delivery': {
          'enabled': true,
          'restaurant_latitude': 13.0827,
          'restaurant_longitude': 80.2707,
          'max_delivery_distance_km': 10,
          'pricing': {
            'type': 'distance',
            'slabs': [
              {'up_to_km': 5, 'fee': 35},
            ]
          }
        }
      };

      final settings = RestaurantSettings.fromFirestore(map);
      expect(settings.isOpen, isFalse);
      expect(settings.minimumOrderValue, equals(200.0));
      expect(settings.pause.isPaused, isTrue);
      expect(settings.specialClosures.length, equals(1));
      expect(settings.specialClosures[0].reason, equals('Festival'));
      expect(settings.delivery.slabs[0].fee, equals(35.0));
    });
  });
}
