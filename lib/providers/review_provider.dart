import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/review.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

final reviewsByLocationProvider = FutureProvider.family<List<Review>, String>((ref, locationId) async {
  if (!AppConstants.isSupabaseConfigured) return [];
  final service = ref.watch(supabaseServiceProvider);
  try {
    final response = await service.client!
        .from('reviews')
        .select('*, user_profiles(name)')
        .eq('location_id', locationId)
        .order('created_at', ascending: false)
        .limit(3);

    return (response as List)
        .map((json) => Review.fromJson(json))
        .toList();
  } on PostgrestException catch (e) {
    throw Exception(e.message);
  }
});

final allReviewsByLocationProvider = FutureProvider.family<List<Review>, String>((ref, locationId) async {
  if (!AppConstants.isSupabaseConfigured) return [];
  final service = ref.watch(supabaseServiceProvider);
  try {
    final response = await service.client!
        .from('reviews')
        .select('*, user_profiles(name)')
        .eq('location_id', locationId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Review.fromJson(json))
        .toList();
  } on PostgrestException catch (e) {
    throw Exception(e.message);
  }
});

class ReviewNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseService _service;

  ReviewNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> addReview(String locationId, Review review) async {
    if (!AppConstants.isSupabaseConfigured || _service.client == null) {
      throw Exception('Supabase non configurato');
    }
    state = const AsyncValue.loading();
    try {
      await _service.client!.from('reviews').insert(review.toJson());
      state = const AsyncValue.data(null);
    } on PostgrestException catch (e) {
      state = AsyncValue.error(Exception(e.message), StackTrace.current);
    }
  }
}

final reviewNotifierProvider = StateNotifierProvider<ReviewNotifier, AsyncValue<void>>((ref) {
  return ReviewNotifier(ref.watch(supabaseServiceProvider));
});
