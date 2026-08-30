import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../config/constants.dart';
import '../models/location.dart';
import '../providers/auth_provider.dart';
import '../providers/local_auth_provider.dart';
import '../providers/location_provider.dart';
import '../services/local_database_service.dart';
import '../widgets/review_card.dart';
import 'location_detail_screen.dart';

class LocationsListScreen extends ConsumerStatefulWidget {
  const LocationsListScreen({super.key});

  @override
  ConsumerState<LocationsListScreen> createState() => _LocationsListScreenState();
}

class _LocationsListScreenState extends ConsumerState<LocationsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocalAuth = ref.watch(localAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Luoghi Salvati'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cerca luoghi...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: _buildLocationsList(isLocalAuth),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsList(bool isLocalAuth) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Location>>(
      future: _loadLocations(isLocalAuth),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allLocations = snapshot.data ?? <Location>[];
        final filter = LocationFilter(query: _searchQuery);
        final filtered = filter.filter(allLocations);

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 64, color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Text(
                  'Nessun luogo trovato',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aggiungi luoghi dalla mappa o effettua il login',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final location = filtered[index];
            return _LocationTile(
              location: location,
              onTap: () => _showLocationDetails(context, location),
            );
          },
        );
      },
    );
  }

  Future<List<Location>> _loadLocations(bool isLocalAuth) async {
    final remoteAsync = ref.read(locationsProvider);
    final remoteLocations = remoteAsync.value ?? <Location>[];
    final localLocations = isLocalAuth
        ? await ref.read(localDatabaseServiceProvider).getLocalLocations()
        : <Location>[];
    return [...remoteLocations, ...localLocations];
  }

  void _showLocationDetails(BuildContext context, Location location) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
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
              backgroundColor: _getCategoryColor(location.category).withOpacity(0.2),
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      GoRouter.of(context).go('/?lat=${location.lat.toStringAsFixed(6)}&lng=${location.lng.toStringAsFixed(6)}');
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Mostra sulla Mappa'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LocationDetailScreen(location: location),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info),
                    label: const Text('Dettagli'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Recensioni recenti',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (location.reviews != null && location.reviews!.isNotEmpty)
              ...location.reviews!.take(3).map((review) => ReviewCard(review: review))
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

class _LocationTile extends StatelessWidget {
  final Location location;
  final VoidCallback onTap;

  const _LocationTile({
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getCategoryColor(location.category),
        child: Icon(
          _getCategoryIcon(),
          color: Colors.white,
        ),
      ),
      title: Text(
        location.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(location.category.label),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                location.averageRating.toStringAsFixed(1),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              Text(
                '${location.reviewCount} recensioni',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
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

  IconData _getCategoryIcon() {
    switch (location.category) {
      case Category.vegan:
        return Icons.eco;
      case Category.healthcare:
        return Icons.local_hospital;
      case Category.general:
        return Icons.place;
    }
  }
}
