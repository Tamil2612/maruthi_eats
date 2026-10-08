import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:maruthi_eats/models/restaurant_settings.dart';
import 'package:maruthi_eats/providers/restaurant_provider.dart';
import 'package:maruthi_eats/services/restaurant_service.dart';

class FakeRestaurantService implements RestaurantService {
  final StreamController<RestaurantSettings> controller =
      StreamController<RestaurantSettings>.broadcast();

  @override
  Stream<RestaurantSettings> streamSettings() => controller.stream;

  @override
  Future<RestaurantSettings> getSettings() async =>
      RestaurantSettings.defaultSettings();
}

void main() {
  group('RestaurantProvider & Availability Real-Time Tests', () {
    test('Initial default settings are OPEN and accepting orders', () {
      final service = FakeRestaurantService();
      final provider = RestaurantProvider(service: service);
      expect(provider.isAcceptingOrders, isTrue);
      expect(provider.statusType, equals(RestaurantStatusType.open));
      expect(provider.statusMessage, contains('Open'));
      provider.dispose();
    });

    test('Transitions to CLOSED when isOpen is false', () {
      final service = FakeRestaurantService();
      final provider = RestaurantProvider(service: service);
      final defaultSettings = RestaurantSettings.defaultSettings();

      final closedSettings = RestaurantSettings(
        isOpen: false,
        timezone: defaultSettings.timezone,
        minimumOrderValue: defaultSettings.minimumOrderValue,
        pause: defaultSettings.pause,
        openingHours: defaultSettings.openingHours,
        specialClosures: defaultSettings.specialClosures,
        delivery: defaultSettings.delivery,
      );

      provider.updateSettings(closedSettings);

      expect(provider.isAcceptingOrders, isFalse);
      expect(provider.statusType, equals(RestaurantStatusType.closed));
      expect(provider.statusMessage, contains('Closed'));
      expect(provider.unavailableReason, equals('Restaurant is closed'));
      provider.dispose();
    });

    test('Transitions to TEMPORARILY_PAUSED when pause is active', () {
      final service = FakeRestaurantService();
      final provider = RestaurantProvider(service: service);
      final defaultSettings = RestaurantSettings.defaultSettings();

      final pausedSettings = RestaurantSettings(
        isOpen: true,
        timezone: defaultSettings.timezone,
        minimumOrderValue: defaultSettings.minimumOrderValue,
        pause: PauseSettings(
          isPaused: true,
          reason: 'High Order Volume',
        ),
        openingHours: defaultSettings.openingHours,
        specialClosures: defaultSettings.specialClosures,
        delivery: defaultSettings.delivery,
      );

      provider.updateSettings(pausedSettings);

      expect(provider.isAcceptingOrders, isFalse);
      expect(provider.statusType, equals(RestaurantStatusType.paused));
      expect(provider.statusMessage, contains('Temporarily unavailable'));
      expect(provider.statusMessage, contains('High Order Volume'));
      expect(provider.unavailableReason, contains('High Order Volume'));
      provider.dispose();
    });

    test('Transitions back to OPEN dynamically when settings flip back', () {
      final service = FakeRestaurantService();
      final provider = RestaurantProvider(service: service);
      final defaultSettings = RestaurantSettings.defaultSettings();

      final pausedSettings = RestaurantSettings(
        isOpen: true,
        timezone: defaultSettings.timezone,
        minimumOrderValue: defaultSettings.minimumOrderValue,
        pause: PauseSettings(isPaused: true, reason: 'Busy'),
        openingHours: defaultSettings.openingHours,
        specialClosures: defaultSettings.specialClosures,
        delivery: defaultSettings.delivery,
      );

      provider.updateSettings(pausedSettings);
      expect(provider.isAcceptingOrders, isFalse);

      // Stream / admin updates settings back to OPEN
      provider.updateSettings(defaultSettings);
      expect(provider.isAcceptingOrders, isTrue);
      expect(provider.statusType, equals(RestaurantStatusType.open));
      provider.dispose();
    });

    test('Delivery disabled marks availability as CLOSED', () {
      final service = FakeRestaurantService();
      final provider = RestaurantProvider(service: service);
      final defaultSettings = RestaurantSettings.defaultSettings();

      final noDeliverySettings = RestaurantSettings(
        isOpen: true,
        timezone: defaultSettings.timezone,
        minimumOrderValue: defaultSettings.minimumOrderValue,
        pause: defaultSettings.pause,
        openingHours: defaultSettings.openingHours,
        specialClosures: defaultSettings.specialClosures,
        delivery: DeliverySettings(
          enabled: false,
          restaurantLatitude: defaultSettings.delivery.restaurantLatitude,
          restaurantLongitude: defaultSettings.delivery.restaurantLongitude,
          maxDeliveryDistanceKm: defaultSettings.delivery.maxDeliveryDistanceKm,
          slabs: defaultSettings.delivery.slabs,
        ),
      );

      provider.updateSettings(noDeliverySettings);

      expect(provider.isAcceptingOrders, isFalse);
      expect(provider.statusType, equals(RestaurantStatusType.closed));
      expect(provider.statusMessage, contains('Delivery is currently disabled'));
      provider.dispose();
    });
  });
}
