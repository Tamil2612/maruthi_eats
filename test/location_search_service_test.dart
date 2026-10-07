import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maruthi_eats/services/location_search_service.dart';

void main() {
  group('LocationSearchService tests', () {
    test('generateSessionToken generates a valid UUID v4 format', () {
      final token1 = LocationSearchService.generateSessionToken();
      final token2 = LocationSearchService.generateSessionToken();

      expect(token1, isNotEmpty);
      expect(token2, isNotEmpty);
      expect(token1, isNot(equals(token2)));

      final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          caseSensitive: false);
      expect(uuidRegex.hasMatch(token1), isTrue,
          reason: '$token1 should match UUID v4 regex');
      expect(uuidRegex.hasMatch(token2), isTrue,
          reason: '$token2 should match UUID v4 regex');
    });

    test('LocationSuggestion instantiates correctly', () {
      final suggestion = LocationSuggestion(
        title: 'Dubai Mall',
        subtitle: 'Financial Center Road, Dubai',
        placeId: 'ChIJN1t_tDeuEmsRUsoyG83frY4',
        location: const LatLng(25.1972, 55.2744),
      );

      expect(suggestion.title, 'Dubai Mall');
      expect(suggestion.subtitle, 'Financial Center Road, Dubai');
      expect(suggestion.placeId, 'ChIJN1t_tDeuEmsRUsoyG83frY4');
      expect(suggestion.location?.latitude, 25.1972);
      expect(suggestion.location?.longitude, 55.2744);
    });

    test('PlaceDetails instantiates correctly', () {
      final details = PlaceDetails(
        placeId: 'ChIJN1t_tDeuEmsRUsoyG83frY4',
        displayName: 'Dubai Mall',
        formattedAddress: 'Financial Center Rd, Dubai',
        location: const LatLng(25.1972, 55.2744),
      );

      expect(details.placeId, 'ChIJN1t_tDeuEmsRUsoyG83frY4');
      expect(details.displayName, 'Dubai Mall');
      expect(details.formattedAddress, 'Financial Center Rd, Dubai');
      expect(details.location.latitude, 25.1972);
      expect(details.location.longitude, 55.2744);
    });

    test('fetchSuggestions returns empty list for short query', () async {
      final results = await LocationSearchService.fetchSuggestions('a');
      expect(results, isEmpty);
    });
  });
}
