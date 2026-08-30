import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/location.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/service_provider.dart';
import '../widgets/custom_map_marker.dart';
import '../widgets/review_card.dart';
import 'location_detail_screen.dart';
import 'filter_search_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  Category? _selectedCategory;
  String _searchQuery = '';
  final List<Marker> _markers = [];
  final List<Category> _selectedCategories = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(41.9028, 12.4964),
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (_, point) {
                _showFilterSearchSheet(context);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.freemapreview',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cerca luoghi...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (query) async {
                      setState(() => _searchQuery = query);
                      _loadFilteredLocations();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: Category.values.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                            _loadFilteredLocations();
                          },
                          backgroundColor: theme.colorScheme.surface,
                          selectedColor: _getCategoryColor(category),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _showFilterSearchSheet(context),
              icon: const Icon(Icons.filter_list),
              label: const Text('Filtri'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFilteredLocations() async {
    final asyncLocations = ref.read(locationsProvider);

    asyncLocations.when(
      data: (allLocations) {
        final filter = LocationFilter(
          categories: _selectedCategories,
          query: _searchQuery,
        );
        final filteredLocations = filter.filter(allLocations);
        setState(() {
          _markers.clear();
          for (final location in filteredLocations) {
            _markers.add(_createMarker(location));
          }
        });
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  Future<void> _searchLocations(String query) async {
    try {
      final locations = await ref.read(mapServiceProvider).searchPlaces(query);
      if (mounted) {
        setState(() {
          _markers.clear();
          for (final location in locations) {
            _markers.add(_createMarker(location));
          }
        });
      }
    } catch (_) {}
  }

  Marker _createMarker(Location location) {
    return Marker(
      point: LatLng(location.lat, location.lng),
      width: 40,
      height: 40,
      child: CustomMapMarker(
        location: location,
        onTap: () => _showLocationDetails(location),
      ),
    );
  }

  void _showLocationDetails(Location location) {
    if (AppConstants.isWeb) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(location.name),
          content: LocationDetailContent(location: location),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => LocationDetailContent(
            location: location,
            scrollController: controller,
          ),
        ),
      );
    }
  }

  Future<LatLng?> _getCurrentPosition() async {
    try {
      final service = ref.read(mapServiceProvider);
      final hasPermission = await service.checkLocationPermission();
      if (!hasPermission) return null;
      return await service.getCurrentLocation();
    } catch (_) {
      return null;
    }
  }

  void _showFilterSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterSearchSheet(
        onSearchCompleted: _loadFilteredLocations,
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

class LocationDetailContent extends StatelessWidget {
  final Location location;
  final ScrollController? scrollController;

  const LocationDetailContent({
    super.key,
    required this.location,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          location.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Chip(
              label: Text(location.category.label),
              backgroundColor: _getCategoryColor().withOpacity(0.2),
            ),
            if (location.isVerified) ...[
              const SizedBox(width: 8),
              const Chip(
                label: Text('Verificato'),
                avatar: Icon(Icons.verified, size: 16, color: Colors.blue),
              ),
            ],
          ],
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
          'Recensioni recenti',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (location.reviews != null && location.reviews!.isNotEmpty)
          ...location.reviews!.take(3).map((review) => ReviewCard(review: review))
        else
          const Text('Nessuna recensione ancora'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LocationDetailScreen(locationId: location.id),
              ),
            );
          },
          child: const Text('Visualizza Dettaglio'),
        ),
      ],
    );
  }

  Color _getCategoryColor() {
    switch (location.category) {
      case Category.vegan:
        return const Color(0xFF4CAF50);
      case Category.healthcare:
        return const Color(0xFF2196F3);
      case Category.general:
        return const Color(0xFFFF9800);
    }
  }
}
