// lib/storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';

class StorageService {
  static const String tripsBox = 'trips_box';

  /// Must be called once (e.g. from main()) before using other methods.
  static Future<void> init() async {
    await Hive.initFlutter();
    // open a box that stores Map objects (trip maps)
    if (!Hive.isBoxOpen(tripsBox)) {
      await Hive.openBox<Map>(tripsBox);
    }
  }

  static Box<Map> trips() {
    if (!Hive.isBoxOpen(tripsBox)) {
      throw StateError('Hive box "$tripsBox" is not open. Call StorageService.init() first.');
    }
    return Hive.box<Map>(tripsBox);
  }

  // helpers
  static Future<void> saveTrip(Trip t) async {
    await trips().put(t.id, t.toMap());
  }

  static Future<void> deleteTrip(String id) async {
    await trips().delete(id);
  }

  static List<Trip> allTrips() {
    final box = trips();
    final List<Trip> result = [];
    for (final dynamic val in box.values) {
      if (val is Map) {
        try {
          final Map<String, dynamic> map = Map<String, dynamic>.from(val);
          result.add(Trip.fromMap(map));
        } catch (e) {
          // ignore malformed entry
        }
      }
    }
    return result;
  }
}
