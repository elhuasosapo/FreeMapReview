import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location.dart';
import '../models/review.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

final locationsProvider = FutureProvider<List<Location>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final user = service.currentUser;
  if (user == null) return [];

  try {
    final response = await service.client
        .from('locations')
        .select('*, reviews(*)')
        .order('created_at', ascending: false);

    final locations = (response as List)
        .map((json) {
          final reviewsJson = json['reviews'] as List<dynamic>?;
          final reviews = reviewsJson
              ?.map((r) => Review.fromJson(r as Map<String, dynamic>))
              .toList() ?? [];
          return Location.fromJson(json, reviews: reviews);
        })
        .toList();

    return locations;
  } on PostgrestException catch (e) {
    throw Exception(e.message);
  }
});

final locationByIdProvider = FutureProvider.family<Location?, String>((ref, id) async {
  final service = ref.watch(supabaseServiceProvider);
  try {
    final response = await service.client
        .from('locations')
        .select('*, reviews(*)')
        .eq('id', id)
        .single();

    final reviewsJson = response['reviews'] as List<dynamic>?;
    final reviews = reviewsJson
        ?.map((r) => Review.fromJson(r as Map<String, dynamic>))
        .toList() ?? [];

    return Location.fromJson(response, reviews: reviews);
  } on PostgrestException catch (e) {
    if (e.code == 'PGRST116') return null;
    throw Exception(e.message);
  }
});

final locationCategoriesProvider = Provider<Set<Category>>((ref) {
  return {Category.vegan, Category.healthcare, Category.general};
});

class LocationFilter {
  final List<Category> categories;
  final String query;

  const LocationFilter({
    this.categories = const [],
    this.query = '',
  });

  List<Location> filter(List<Location> locations) {
    var filtered = locations;
    if (categories.isNotEmpty) {
      filtered = filtered.where((l) => categories.contains(l.category)).toList();
    }
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      filtered = filtered.where((l) {
        return l.name.toLowerCase().contains(lowerQuery) ||
            (l.description != null && l.description!.toLowerCase().contains(lowerQuery));
      }).toList();
    }
    return filtered;
  }
}

final locationFilterProvider = StateProvider<LocationFilter>((ref) => const LocationFilter());

class LocationNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseService _service;

  LocationNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> addLocation(Location location) async {
    state = const AsyncValue.loading();
    try {
      await _service.client.from('locations').insert(location.toJson());
      state = const AsyncValue.data(null);
    } on PostgrestException catch (e) {
      state = AsyncValue.error(Exception(e.message), StackTrace.current);
    }
  }
}

final locationNotifierProvider = StateNotifierProvider<LocationNotifier, AsyncValue<void>>((ref) {
  return LocationNotifier(ref.watch(supabaseServiceProvider));
});
