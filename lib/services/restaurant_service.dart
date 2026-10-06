import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_settings.dart';

class RestaurantService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Streams restaurant settings in real time
  Stream<RestaurantSettings> streamSettings() {
    return _db.collection('settings').doc('restaurant').snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return RestaurantSettings.defaultSettings();
      }
      return RestaurantSettings.fromFirestore(snapshot.data()!);
    });
  }

  /// Fetches current settings once
  Future<RestaurantSettings> getSettings() async {
    try {
      final doc = await _db.collection('settings').doc('restaurant').get();
      if (!doc.exists || doc.data() == null) {
        return RestaurantSettings.defaultSettings();
      }
      return RestaurantSettings.fromFirestore(doc.data()!);
    } catch (_) {
      return RestaurantSettings.defaultSettings();
    }
  }
}
