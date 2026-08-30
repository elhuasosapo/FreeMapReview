import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/location.dart';
import '../models/review.dart';

class LocalDatabaseService {
  static const String _locationsFile = 'local_locations.json';
  static const String _reviewsFile = 'local_reviews.json';
  static const String _syncQueueFile = 'sync_queue.json';

  Future<Directory> get _localDir async {
    final dir = await getApplicationDocumentsDirectory();
    return dir;
  }

  Future<File> _getFile(String fileName) async {
    final dir = await _localDir;
    return File('${dir.path}/$fileName');
  }

  Future<List<Map<String, dynamic>>> _readJson(String fileName) async {
    try {
      final file = await _getFile(fileName);
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      return List<Map<String, dynamic>>.from(jsonDecode(content));
    } catch (e) {
      return [];
    }
  }

  Future<void> _writeJson(String fileName, List<Map<String, dynamic>> data) async {
    final file = await _getFile(fileName);
    await file.writeAsString(jsonEncode(data));
  }

  Future<void> saveLocation(Location location) async {
    final locations = await _readJson(_locationsFile);
    final existingIndex = locations.indexWhere((l) => l['id'] == location.id);
    final locationMap = location.toJson();
    locationMap['sync_status'] = 'pending';
    if (existingIndex >= 0) {
      locations[existingIndex] = locationMap;
    } else {
      locations.add(locationMap);
    }
    await _writeJson(_locationsFile, locations);
    await _addToSyncQueue('location', location.id, 'upsert');
  }

  Future<List<Location>> getLocalLocations() async {
    final locations = await _readJson(_locationsFile);
    return locations.map((json) => Location.fromJson(json)).toList();
  }

  Future<void> deleteLocalLocation(String id) async {
    final locations = await _readJson(_locationsFile);
    locations.removeWhere((l) => l['id'] == id);
    await _writeJson(_locationsFile, locations);
    await _addToSyncQueue('location', id, 'delete');
  }

  Future<void> saveReview(Review review) async {
    final reviews = await _readJson(_reviewsFile);
    final existingIndex = reviews.indexWhere((r) => r['id'] == review.id);
    final reviewMap = review.toJson();
    reviewMap['sync_status'] = 'pending';
    if (existingIndex >= 0) {
      reviews[existingIndex] = reviewMap;
    } else {
      reviews.add(reviewMap);
    }
    await _writeJson(_reviewsFile, reviews);
    await _addToSyncQueue('review', review.id, 'upsert');
  }

  Future<List<Review>> getLocalReviews(String locationId) async {
    final reviews = await _readJson(_reviewsFile);
    final filtered = reviews.where((r) => r['location_id'] == locationId).toList();
    return filtered.map((json) => Review.fromJson(json)).toList();
  }

  Future<void> _addToSyncQueue(String entityType, String entityId, String operation) async {
    final queue = await _readJson(_syncQueueFile);
    queue.add({
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'timestamp': DateTime.now().toIso8601String(),
      'retries': 0,
    });
    await _writeJson(_syncQueueFile, queue);
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    return await _readJson(_syncQueueFile);
  }

  Future<void> clearSyncQueue() async {
    await _writeJson(_syncQueueFile, []);
  }

  Future<void> markSynced(String entityId) async {
    final queue = await _readJson(_syncQueueFile);
    queue.removeWhere((item) => item['entity_id'] == entityId);
    await _writeJson(_syncQueueFile, queue);

    final locations = await _readJson(_locationsFile);
    for (var loc in locations) {
      if (loc['id'] == entityId) {
        loc['sync_status'] = 'synced';
      }
    }
    await _writeJson(_locationsFile, locations);

    final reviews = await _readJson(_reviewsFile);
    for (var rev in reviews) {
      if (rev['id'] == entityId) {
        rev['sync_status'] = 'synced';
      }
    }
    await _writeJson(_reviewsFile, reviews);
  }

  Future<void> clearAllLocalData() async {
    await _writeJson(_locationsFile, []);
    await _writeJson(_reviewsFile, []);
    await _writeJson(_syncQueueFile, []);
  }
}
