import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_database_service.dart';

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});

final localAuthProvider = StateProvider<bool>((ref) => false);

final localUserProvider = StateProvider<String?>((ref) => null);
