import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final authStateProvider = StreamProvider<bool>((ref) {
  if (!AppConstants.isSupabaseConfigured) return const Stream.empty();
  final service = ref.watch(supabaseServiceProvider);
  return service.authStateChanges.map((state) => state.session != null);
});

final currentUserProvider = Provider<User?>((ref) {
  if (!AppConstants.isSupabaseConfigured) return null;
  final service = ref.watch(supabaseServiceProvider);
  return service.currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  if (!AppConstants.isSupabaseConfigured) return false;
  final service = ref.watch(supabaseServiceProvider);
  return service.isAuthenticated;
});
