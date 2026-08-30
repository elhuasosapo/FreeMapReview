import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_database_service.dart';

const String _kLocalAuthKey = 'local_auth';
const String _kLocalUserKey = 'local_user';
const String _kRememberMeKey = 'remember_me';

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});

final localAuthProvider = StateProvider<bool>((ref) => false);

final localUserProvider = StateProvider<String?>((ref) => null);

final rememberMeProvider = StateProvider<bool>((ref) => false);

final initialLocalAuthProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final remember = prefs.getBool(_kRememberMeKey) ?? false;
  if (!remember) return false;

  final isAuth = prefs.getBool(_kLocalAuthKey) ?? false;
  final user = prefs.getString(_kLocalUserKey);
  return isAuth && user != null && user.isNotEmpty;
});

final localAuthNotifierProvider = Provider<ValueNotifier<bool>>((ref) {
  return ValueNotifier<bool>(false);
});

Future<void> saveLocalAuth(bool isAuth, String? user, {bool remember = false}) async {
  final prefs = await SharedPreferences.getInstance();
  if (remember) {
    await prefs.setBool(_kLocalAuthKey, isAuth);
    await prefs.setString(_kLocalUserKey, user ?? '');
    await prefs.setBool(_kRememberMeKey, true);
  } else {
    await prefs.remove(_kLocalAuthKey);
    await prefs.remove(_kLocalUserKey);
    await prefs.setBool(_kRememberMeKey, false);
  }
}

Future<bool> loadLocalAuth() async {
  final prefs = await SharedPreferences.getInstance();
  final remember = prefs.getBool(_kRememberMeKey) ?? false;
  if (!remember) return false;

  final isAuth = prefs.getBool(_kLocalAuthKey) ?? false;
  final user = prefs.getString(_kLocalUserKey);

  return isAuth && user != null && user.isNotEmpty;
}

Future<String?> loadLocalUser() async {
  final prefs = await SharedPreferences.getInstance();
  final remember = prefs.getBool(_kRememberMeKey) ?? false;
  if (!remember) return null;

  final user = prefs.getString(_kLocalUserKey);
  return (user != null && user.isNotEmpty) ? user : null;
}

Future<void> clearLocalAuth() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kLocalAuthKey);
  await prefs.remove(_kLocalUserKey);
  await prefs.setBool(_kRememberMeKey, false);
}
