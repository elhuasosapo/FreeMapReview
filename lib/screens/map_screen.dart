import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/constants.dart';
import '../models/location.dart';
import '../providers/auth_provider.dart';
import '../providers/local_auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/service_provider.dart';
import '../widgets/custom_map_marker.dart';
import '../widgets/review_card.dart';
import 'location_detail_screen.dart';
import 'filter_search_sheet.dart';
import 'local_login_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  final LatLng? initialTarget;
  const MapScreen({super.key, this.initialTarget});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  String _searchQuery = '';
  final List<Marker> _markers = [];
  final List<Category> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AsyncValue<List<Location>>>(
        locationsProvider,
        (previous, next) {
          if (next.hasValue) {
            _loadFilteredLocations();
          }
        },
      );
      _loadFilteredLocations();
    });

    if (widget.initialTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(widget.initialTarget!, 16);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final isLocalAuth = ref.watch(localAuthProvider);

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
                   child: Row(
                      children: [
                        Expanded(
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
                        if (isLocalAuth)
                          IconButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Logout'),
                                  content: const Text('Vuoi effettuare il logout locale?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                ref.read(localAuthProvider.notifier).state = false;
                                ref.read(localUserProvider.notifier).state = null;
                                ref.read(rememberMeProvider.notifier).state = false;
                                ref.read(localAuthNotifierProvider).value = false;
                                await clearLocalAuth();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Logout effettuato')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.logout),
                            tooltip: 'Logout',
                          ),
                        if (!isLocalAuth && !isAuthenticated)
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const LocalLoginScreen()),
                              );
                            },
                            icon: const Icon(Icons.login),
                            tooltip: 'Login Locale',
                          ),
                     ],
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
            left: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () {
                GoRouter.of(context).go('/locations');
              },
              backgroundColor: theme.colorScheme.tertiary,
              foregroundColor: theme.colorScheme.onTertiary,
              child: const Icon(Icons.list),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _openLocationSelector(context),
              icon: const Icon(Icons.edit_location),
              label: const Text('Gestione Mappa'),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 88,
            child: FloatingActionButton(
              onPressed: _centerOnUserPosition,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFilteredLocations() async {
    final asyncLocations = ref.read(locationsProvider);

    asyncLocations.when(
      data: (allLocations) async {
        var combinedLocations = List<Location>.from(allLocations);
        if (combinedLocations.isEmpty && ref.read(localAuthProvider)) {
          final localLocations = await ref.read(localDatabaseServiceProvider).getLocalLocations();
          combinedLocations = [...combinedLocations, ...localLocations];
        }
        final filter = LocationFilter(
          categories: _selectedCategories,
          query: _searchQuery,
        );
        final filteredLocations = filter.filter(combinedLocations);
        if (mounted) {
          setState(() {
            _markers.clear();
            for (final location in filteredLocations) {
              _markers.add(_createMarker(location));
            }
          });
        }
      },
      loading: () {},
      error: (_, __) {},
    );
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

  Future<void> _showFilterSearchSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterSearchSheet(
        onSearchCompleted: _loadFilteredLocations,
      ),
    );
    return;
  }

  Future<void> _centerOnUserPosition() async {
    final service = ref.read(mapServiceProvider);
    final hasPermission = await service.checkLocationPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permessi di localizzazione negati')),
      );
      return;
    }
    final position = await service.getCurrentLocation();
    if (position != null && mounted) {
      _mapController.move(position, 15.0);
    }
  }

  Future<void> _openLocationSelector(BuildContext context) async {
    // Passo la posizione iniziale come query params
    final initialLat = _mapController.center.latitude;
    final initialLng = _mapController.center.longitude;
    
    final selectedPosition = await Navigator.push<LatLng?>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationSelectorScreen(
          mapController: _mapController,
          initialCenter: _mapController.center ?? const LatLng(41.9028, 12.4964),
        ),
      ),
    );

    if (selectedPosition != null && mounted) {
      // Navigator.push ha già riportato la MapScreen attiva; navighiamo direttamente
      // alla schermata di aggiunta location senza pop aggiuntivi sul GoRouter.
      context.go('/add-location?lat=${selectedPosition.latitude}&lng=${selectedPosition.longitude}');
    }
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
class LocationSelectorScreen extends ConsumerStatefulWidget {
  final MapController mapController;
  final LatLng initialCenter;

  const LocationSelectorScreen({
    super.key,
    required this.mapController,
    required this.initialCenter,
  });

  @override
  ConsumerState<LocationSelectorScreen> createState() => _LocationSelectorScreenState();
}

class _LocationSelectorScreenState extends ConsumerState<LocationSelectorScreen> {
  final MapController _localMapController = MapController();
  LatLng _selectedPosition = const LatLng(41.9028, 12.4964);

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialCenter;
  }

  @override
  void dispose() {
    _localMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleziona Posizione'),
        actions: [
          IconButton(
            onPressed: _centerOnUserPosition,
            icon: const Icon(Icons.my_location),
            tooltip: 'Posizione corrente',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _localMapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (_, point) {
                setState(() => _selectedPosition = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.freemapreview',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.3),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Posizione selezionata:',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${_selectedPosition.latitude.toStringAsFixed(6)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'Lng: ${_selectedPosition.longitude.toStringAsFixed(6)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: ElevatedButton.icon(
              onPressed: () {
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      Navigator.of(context).pop(_selectedPosition);
                    }
                  });
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Conferma Selezione'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _centerOnUserPosition() async {
    try {
      final service = ref.read(mapServiceProvider);
      final hasPermission = await service.checkLocationPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permessi di localizzazione negati')),
        );
        return;
      }
      final position = await service.getCurrentLocation();
      if (position != null && mounted) {
        setState(() => _selectedPosition = position);
        _localMapController.move(position, 15.0);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile ottenere la posizione')),
      );
    }
  }
}
