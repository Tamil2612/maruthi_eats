import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
  static const String _mapsApiKey = String.fromEnvironment('MAPS_API_KEY');

  /// Generates a UUID v4 session token for Google Places API autocomplete sessions.
  static String generateSessionToken() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // UUID v4 version
    values[8] = (values[8] & 0x3f) | 0x80; // UUID v4 variant
    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Fetches place predictions using Google Places API (New) Autocomplete endpoint.
  static Future<List<LocationSuggestion>> fetchSuggestions(
    String query, {
    String? apiKey,
    String? sessionToken,
    LatLng? locationBias,
  }) async {
    final key = apiKey ?? _mapsApiKey;
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) return [];

    // 1. Try Google Places API (New) – Autocomplete (New) HTTP API
    if (key.isNotEmpty) {
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

        final response = await http
            .post(
              Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
              headers: {
                'Content-Type': 'application/json',
                'X-Goog-Api-Key': key,
              },
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 4));

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
            return results;
          }
        } else {
          debugPrint(
              'Places Autocomplete (New) status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('Places Autocomplete (New) API error: $e');
      }

      // 2. Fallback to Legacy Places API if Places (New) failed or returned empty
      try {
        final sessionParam = (sessionToken != null && sessionToken.isNotEmpty)
            ? '&sessiontoken=$sessionToken'
            : '';
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(trimmedQuery)}'
          '$sessionParam'
          '&key=$key',
        );
        final response =
            await http.get(url).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'OK' && data['predictions'] is List) {
            final predictions = data['predictions'] as List;
            return predictions.map((p) {
              final structured = p['structured_formatting'] ?? {};
              return LocationSuggestion(
                title: structured['main_text'] ?? p['description'] ?? trimmedQuery,
                subtitle: structured['secondary_text'] ?? '',
                placeId: p['place_id'],
              );
            }).toList();
          }
        }
      } catch (e) {
        debugPrint('Legacy Places Autocomplete API fallback error: $e');
      }
    }

    // 3. Fallback: Geocoding plugin locationFromAddress
    try {
      final locations = await Geocoding().locationFromAddress(trimmedQuery);
      final List<LocationSuggestion> fallbackResults = [];

      for (var loc in locations.take(5)) {
        try {
          final placemarks = await Geocoding()
              .placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final title = [p.name, p.subLocality]
                .where((s) => s != null && s.isNotEmpty && s.toLowerCase() != 'null')
                .join(', ');
            final subtitle = [p.locality, p.administrativeArea, p.country]
                .where((s) => s != null && s.isNotEmpty && s.toLowerCase() != 'null')
                .join(', ');

            fallbackResults.add(LocationSuggestion(
              title: title.isNotEmpty ? title : (p.locality ?? trimmedQuery),
              subtitle: subtitle,
              location: LatLng(loc.latitude, loc.longitude),
            ));
          }
        } catch (_) {
          fallbackResults.add(LocationSuggestion(
            title: trimmedQuery,
            subtitle:
                '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
            location: LatLng(loc.latitude, loc.longitude),
          ));
        }
      }
      return fallbackResults;
    } catch (e) {
      debugPrint('Geocoding fallback error: $e');
      return [];
    }
  }

  /// Retrieves place details using Google Places API (New) Place Details endpoint.
  static Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? apiKey,
    String? sessionToken,
  }) async {
    final key = apiKey ?? _mapsApiKey;
    if (placeId.isEmpty) return null;

    if (key.isNotEmpty) {
      final cleanPlaceId =
          placeId.startsWith('places/') ? placeId.substring(7) : placeId;

      // 1. Try Google Places API (New) – Place Details (New)
      try {
        final headers = <String, String>{
          'X-Goog-Api-Key': key,
          'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
        };

        if (sessionToken != null && sessionToken.isNotEmpty) {
          headers['X-Goog-Session-Token'] = sessionToken;
        }

        final response = await http
            .get(
              Uri.parse('https://places.googleapis.com/v1/places/$cleanPlaceId'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 4));

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
            return PlaceDetails(
              placeId: id,
              displayName: displayName,
              formattedAddress: formattedAddress,
              location: LatLng(lat, lng),
            );
          }
        } else {
          debugPrint(
              'Place Details (New) status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('Place Details (New) API error: $e');
      }

      // 2. Fallback: Legacy Place Details API
      try {
        final sessionParam = (sessionToken != null && sessionToken.isNotEmpty)
            ? '&sessiontoken=$sessionToken'
            : '';
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$cleanPlaceId'
          '&fields=place_id,name,formatted_address,geometry'
          '$sessionParam'
          '&key=$key',
        );

        final response =
            await http.get(url).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'OK' && data['result'] != null) {
            final result = data['result'];
            final id = result['place_id'] ?? cleanPlaceId;
            final name = result['name'] ?? '';
            final address = result['formatted_address'] ?? '';
            final loc = result['geometry']?['location'];

            if (loc != null && loc['lat'] != null && loc['lng'] != null) {
              return PlaceDetails(
                placeId: id,
                displayName: name,
                formattedAddress: address,
                location: LatLng(
                  (loc['lat'] as num).toDouble(),
                  (loc['lng'] as num).toDouble(),
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Legacy Place details error: $e');
      }
    }

    return null;
  }

  /// Resolves location coordinates for a given suggestion.
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

    // Fallback: Geocode using title + subtitle
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
