import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';
import '../widgets/review_card.dart';
import 'add_review_screen.dart';

class LocationDetailScreen extends ConsumerWidget {
  final String locationId;

  const LocationDetailScreen({
    super.key,
    required this.locationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locationAsync = ref.watch(locationByIdProvider(locationId));
    final reviewsAsync = ref.watch(reviewsByLocationProvider(locationId));
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettaglio Luogo'),
        actions: [
          if (isAuthenticated)
            IconButton(
              icon: const Icon(Icons.rate_review),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddReviewScreen(locationId: locationId),
                  ),
                );
              },
            ),
        ],
      ),
      body: locationAsync.when(
        data: (location) {
          if (location == null) {
            return const Center(child: Text('Luogo non trovato'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(location.category.label),
                  backgroundColor: _getCategoryColor(location.category),
                ),
                const SizedBox(height: 16),
                if (location.description != null && location.description!.isNotEmpty)
                  Text(location.description!),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      location.averageRating.toStringAsFixed(1),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${location.reviewCount} recensioni',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Recensioni',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                reviewsAsync.when(
                  data: (reviews) {
                    if (reviews.isEmpty) {
                      return const Text('Nessuna recensione ancora');
                    }
                    return Column(
                      children: reviews
                          .map((r) => ReviewCard(review: r, showFullText: true))
                          .toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Errore: $e'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
      ),
    );
  }

  Color _getCategoryColor(Category category) {
    switch (category) {
      case Category.vegan:
        return const Color(0xFF4CAF50);
      case Category.healthcare:
        return const Color(0xFF2196F3);
      case Category.general:
        return const Color(0xFFFF9800);
    }
  }
}
