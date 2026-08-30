import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/map_service.dart';

final mapServiceProvider = Provider<MapService>((ref) {
  return MapService();
});
