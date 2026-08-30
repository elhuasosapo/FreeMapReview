import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final authStateProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  if (!AppConstants.isSupabaseConfigured || service.client == null) return const Stream.empty();
  return service.authStateChanges.map((state) => state.session != null);
});

final currentUserProvider = Provider<User?>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  if (!AppConstants.isSupabaseConfigured || service.client == null) return null;
  return service.currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  if (!AppConstants.isSupabaseConfigured || service.client == null) return false;
  return service.isAuthenticated;
});
