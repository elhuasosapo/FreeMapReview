import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';

class SupabaseService {
  SupabaseClient? client;

  SupabaseService() {
    if (AppConstants.isSupabaseConfigured) {
      client = Supabase.instance.client;
    }
  }

  SupabaseClient? get instance => client;

  User? get currentUser => client?.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges =>
      client != null ? client!.auth.onAuthStateChange : const Stream.empty();

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    if (!AppConstants.isSupabaseConfigured || client == null) {
      throw Exception('Supabase non configurato');
    }
    try {
      return await client!.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (!AppConstants.isSupabaseConfigured || client == null) {
      throw Exception('Supabase non configurato');
    }
    try {
      return await client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> signOut() async {
    if (!AppConstants.isSupabaseConfigured || client == null) {
      throw Exception('Supabase non configurato');
    }
    try {
      await client!.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> resetPassword(String email) async {
    if (!AppConstants.isSupabaseConfigured || client == null) {
      throw Exception('Supabase non configurato');
    }
    try {
      await client!.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }
}
