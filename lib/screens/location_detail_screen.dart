import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';
import '../widgets/review_card.dart';
import 'add_review_screen.dart';

class LocationDetailScreen extends ConsumerWidget {
  final String? locationId;
  final Location? location;

  const LocationDetailScreen({
    super.key,
    this.locationId,
    this.location,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (location != null) {
      return _buildScaffold(context, theme, location!);
    }

    if (locationId == null) {
      return const Scaffold(body: Center(child: Text('Luogo non valido')));
    }

    final locationAsync = ref.watch(locationByIdProvider(locationId!));
    final reviewsAsync = ref.watch(reviewsByLocationProvider(locationId!));
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
                    builder: (_) => AddReviewScreen(locationId: locationId!),
                  ),
                );
              },
            ),
        ],
      ),
      body: locationAsync.when(
        data: (loc) {
          if (loc == null) {
            return const Center(child: Text('Luogo non trovato'));
          }
          return _buildScaffold(context, theme, loc);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, ThemeData theme, Location loc) {
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(loc.category.label),
              backgroundColor: _getCategoryColor(loc.category),
            ),
            const SizedBox(height: 16),
            if (loc.description != null && loc.description!.isNotEmpty)
              Text(loc.description!),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  loc.averageRating.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(width: 16),
                Text(
                  '${loc.reviewCount} recensioni',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Recensioni recenti',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (loc.reviews != null && loc.reviews!.isNotEmpty)
              ...loc.reviews!.take(3).map((r) => ReviewCard(review: r, showFullText: true))
            else
              const Text('Nessuna recensione ancora'),
          ],
        ),
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
