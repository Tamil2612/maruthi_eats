import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class LocationSuggestion {
  final String title;
  final String subtitle;
  final LatLng? location;
  final String? placeId;

  LocationSuggestion({
    required this.title,
    required this.subtitle,
    this.location,
    this.placeId,
  });
}

class PlaceDetails {
  final String placeId;
  final String displayName;
  final String formattedAddress;
  final LatLng location;

  PlaceDetails({
    required this.placeId,
    required this.displayName,
    required this.formattedAddress,
    required this.location,
  });
}

class LocationSearchService {
  static const MethodChannel _channel = MethodChannel('com.maruthieats.app/config');
  static String? _cachedApiKey;
  static String? _cachedPackageName;
  static String? _cachedSha1;

  /// Retrieves the Android package name and SHA-1 cert fingerprint for Android API key restriction verification.
  static Future<Map<String, String>> _getAndroidHeaders() async {
    if (kIsWeb) return {};

    if (_cachedPackageName != null && _cachedSha1 != null) {
      final map = <String, String>{};
      if (_cachedPackageName!.isNotEmpty) map['X-Android-Package'] = _cachedPackageName!;
      if (_cachedSha1!.isNotEmpty) map['X-Android-Cert'] = _cachedSha1!;
      return map;
    }

    try {
      final Map<dynamic, dynamic>? info =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getAndroidHeaderInfo');
      if (info != null) {
        _cachedPackageName = info['packageName']?.toString() ?? '';
        _cachedSha1 = info['sha1']?.toString() ?? '';
        final map = <String, String>{};
        if (_cachedPackageName!.isNotEmpty) map['X-Android-Package'] = _cachedPackageName!;
        if (_cachedSha1!.isNotEmpty) map['X-Android-Cert'] = _cachedSha1!;
        return map;
      }
    } catch (e) {
      debugPrint('Failed to retrieve Android header info: $e');
    }
    return {};
  }

  /// Retrieves the Google Maps API key from environment or native Android configuration.
  static Future<String> getApiKey({String? overrideKey}) async {
    if (overrideKey != null && overrideKey.isNotEmpty) {
      return overrideKey;
    }

    const envKey = String.fromEnvironment('MAPS_API_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }

    if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
      return _cachedApiKey!;
    }

    try {
      final nativeKey = await _channel.invokeMethod<String>('getMapsApiKey');
      if (nativeKey != null && nativeKey.isNotEmpty) {
        _cachedApiKey = nativeKey;
        return nativeKey;
      }
    } catch (e) {
      debugPrint('Failed to retrieve native MAPS_API_KEY: $e');
    }

    return '';
  }

  /// Generates a UUID v4 session token for Google Places API autocomplete sessions.
  static String generateSessionToken() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // UUID v4 version
    values[8] = (values[8] & 0x3f) | 0x80; // UUID v4 variant
    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Fetches place predictions using ONLY Google Places API (New) Autocomplete endpoint.
  static Future<List<LocationSuggestion>> fetchSuggestions(
    String query, {
    String? apiKey,
    String? sessionToken,
    LatLng? locationBias,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    final key = await getApiKey(overrideKey: apiKey);
    debugPrint('Places API key available: ${key.isNotEmpty}');
    debugPrint('Autocomplete query: $trimmedQuery');

    if (key.isEmpty) {
      debugPrint('Places Autocomplete Error: MAPS_API_KEY is not configured or available.');
      return [];
    }

    try {
      final Map<String, dynamic> requestBody = {
        'input': trimmedQuery,
      };

      if (sessionToken != null && sessionToken.isNotEmpty) {
        requestBody['sessionToken'] = sessionToken;
      }

      if (locationBias != null) {
        requestBody['locationBias'] = {
          'circle': {
            'center': {
              'latitude': locationBias.latitude,
              'longitude': locationBias.longitude,
            },
            'radius': 50000.0,
          }
        };
      }

      final androidHeaders = await _getAndroidHeaders();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': key,
        ...androidHeaders,
      };

      final response = await http
          .post(
            Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 5));

      debugPrint('Autocomplete HTTP status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['suggestions'] is List) {
          final suggestionsList = data['suggestions'] as List;
          final List<LocationSuggestion> results = [];

          for (var item in suggestionsList) {
            final pred = item['placePrediction'];
            if (pred == null) continue;

            final rawPlaceId = pred['placeId'] ?? pred['place'];
            String? placeId;
            if (rawPlaceId is String) {
              placeId = rawPlaceId.startsWith('places/')
                  ? rawPlaceId.substring(7)
                  : rawPlaceId;
            }

            final structured = pred['structuredFormat'];
            final mainText = structured?['mainText']?['text'] ??
                pred['text']?['text'] ??
                trimmedQuery;
            final secondaryText = structured?['secondaryText']?['text'] ?? '';

            results.add(LocationSuggestion(
              title: mainText,
              subtitle: secondaryText,
              placeId: placeId,
            ));
          }

          debugPrint('Autocomplete suggestions count: ${results.length}');
          return results;
        } else {
          debugPrint('Autocomplete suggestions count: 0');
          return [];
        }
      } else {
        debugPrint('Places Autocomplete HTTP ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Places Autocomplete HTTP Error: $e');
      return [];
    }
  }

  /// Retrieves place details using ONLY Google Places API (New) Place Details endpoint.
  static Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? apiKey,
    String? sessionToken,
  }) async {
    if (placeId.isEmpty) return null;

    final cleanPlaceId =
        placeId.startsWith('places/') ? placeId.substring(7) : placeId;
    debugPrint('Selected place ID: $cleanPlaceId');

    final key = await getApiKey(overrideKey: apiKey);
    if (key.isEmpty) {
      debugPrint('Place Details Error: MAPS_API_KEY is not configured or available.');
      return null;
    }

    try {
      final androidHeaders = await _getAndroidHeaders();
      final headers = <String, String>{
        'X-Goog-Api-Key': key,
        'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
        ...androidHeaders,
      };

      if (sessionToken != null && sessionToken.isNotEmpty) {
        headers['X-Goog-Session-Token'] = sessionToken;
      }

      final response = await http
          .get(
            Uri.parse('https://places.googleapis.com/v1/places/$cleanPlaceId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));

      debugPrint('Place Details HTTP status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final id = data['id'] ?? cleanPlaceId;
        final displayName = data['displayName']?['text'] ?? '';
        final formattedAddress = data['formattedAddress'] ?? '';
        final locationObj = data['location'];

        if (locationObj != null &&
            locationObj['latitude'] != null &&
            locationObj['longitude'] != null) {
          final lat = (locationObj['latitude'] as num).toDouble();
          final lng = (locationObj['longitude'] as num).toDouble();
          debugPrint('Selected coordinates: $lat, $lng');

          return PlaceDetails(
            placeId: id,
            displayName: displayName,
            formattedAddress: formattedAddress,
            location: LatLng(lat, lng),
          );
        }
      } else {
        debugPrint('Places Details HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Place Details HTTP Error: $e');
    }

    return null;
  }

  /// Resolves location coordinates for a given suggestion using Place Details.
  static Future<LatLng?> resolveLocation(
    LocationSuggestion suggestion, {
    String? apiKey,
    String? sessionToken,
  }) async {
    if (suggestion.location != null) {
      return suggestion.location;
    }

    if (suggestion.placeId != null && suggestion.placeId!.isNotEmpty) {
      final details = await getPlaceDetails(
        suggestion.placeId!,
        apiKey: apiKey,
        sessionToken: sessionToken,
      );
      if (details != null) {
        return details.location;
      }
    }

    // Fallback geocoding only for location resolution if place details returned no geometry
    try {
      final fullText = '${suggestion.title}, ${suggestion.subtitle}'.trim();
      final locations = await Geocoding().locationFromAddress(fullText);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (_) {}

    return null;
  }
}
