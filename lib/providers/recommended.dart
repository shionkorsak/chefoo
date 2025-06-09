import 'dart:convert';
import 'package:chefoo/commons.dart';

class RecommendedProvider with ChangeNotifier {
  List<Place> _recommended = [];
  List<Place> _enriched = [];

  List<Place> get recommended => _recommended;
  List<Place> get enriched => _enriched;

  Future<void> setRecommendations({
    required List<Place> recommended,
    required List<Place> enriched,
    required String uid,
    required Position position,
    required double radius,
  }) async {
    _recommended = recommended;
    _enriched = enriched;
    notifyListeners();

    print('[REC] Setting SharedPreferences.');
    final prefs = await SharedPreferences.getInstance();
    final key = '${uid}_recommended_entries';

    final newEntry = {
      'lat': position.latitude,
      'lng': position.longitude,
      'radius': radius,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'recommended': recommended.map((e) => e.toJson()).toList(),
      'enriched': enriched.map((e) => e.toJson()).toList()
    };

    List<Map<String, dynamic>> entries = [];

    final existingJson = prefs.getString(key);
    if(existingJson != null) {
      entries = List<Map<String, dynamic>>.from(jsonDecode(existingJson));
    }
    
    entries.add(newEntry);
    await prefs.setString(key, jsonEncode(entries));
    print('[REC] Stored to key: $key');
  }

  void clear(String uid) async {
    _recommended = [];
    _enriched = [];
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    for (var key in ['recommended', 'enriched', 'lat', 'lng', 'timestamp']) {
      await prefs.remove('${uid}_$key');
    }
  }
  
  Future<void> loadFromPrefs(String uid, Position currentPosition, {double targetRadius = 1000.0}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${uid}_recommended_entries';
    final entriesJson = prefs.getString(key);

    if (entriesJson == null) {
      print('[REC] No cached entries found key=$key');
      return;
    }

    final List<dynamic> entries = jsonDecode(entriesJson);
    Map<String, dynamic>? nearest;
    double? minDistance;

    for (final entry in entries) {
      final double lat = entry['lat'];
      final double lng = entry['lng'];
      final int timestamp = entry['timestamp'];
      final double entryRadius = entry['radius'] ?? 1000.0;

      final isTooOld = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp)) > Duration(hours: 6);
      if (isTooOld) continue;

      final dist = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        lat,
        lng,
      );

      if (dist <= targetRadius && entryRadius == targetRadius) {  // <== radius filter
        if (minDistance == null || dist < minDistance) {
          minDistance = dist;
          nearest = entry;
        }
      }
    }

    if (nearest == null) {
      print('[REC] No nearby valid cache found.');
      return;
    }

    _recommended = (nearest['recommended'] as List).map((e) => Place.fromJson(e)).toList();
    _enriched = (nearest['enriched'] as List).map((e) => Place.fromJson(e)).toList();

    print('[REC] Loaded ${_recommended.length} recommended from closest cache.');
    notifyListeners();
  }

  Future<void> cleanupOldEntries(String uid) async {
    print('[REC] Cleaning SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    final key = '${uid}_recommended_entries';
    final entriesJson = prefs.getString(key);

    if (entriesJson == null) return;

    final entries = List<Map<String, dynamic>>.from(jsonDecode(entriesJson));
    final cutoff = DateTime.now().subtract(Duration(hours: 3)).millisecondsSinceEpoch;

    final recent = entries.where((e) => e['timestamp'] >= cutoff).toList();
    await prefs.setString(key, jsonEncode(recent));
  }

  Future<bool> hasValidCacheNearby(String uid, Position currentPosition, {double targetRadius = 100.0}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${uid}_recommended_entries';
    final entriesJson = prefs.getString(key);

    if (entriesJson == null) return false;

    final List<dynamic> entries = jsonDecode(entriesJson);
    for (final entry in entries) {
      final double lat = entry['lat'];
      final double lng = entry['lng'];
      final int timestamp = entry['timestamp'];
      final double entryRadius = entry['radius'] ?? 100.0;

      final isTooOld = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(timestamp)) >
          Duration(hours: 6);
      final dist = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        lat,
        lng,
      );

      print('[REC] Cache entry — Dist: $dist, Old: $isTooOld, Radius: $entryRadius');

      if (!isTooOld && dist <= targetRadius && entryRadius == targetRadius) {
        print('[REC] Valid cache found nearby with matching radius');
        return true;
      }
    }

    print('[REC] No valid cache nearby with matching radius');
    return false;
  }

  void forceRefresh() {
    _recommended = List.from(_recommended);
    _enriched = List.from(_enriched);
    
    notifyListeners();
  }
}
