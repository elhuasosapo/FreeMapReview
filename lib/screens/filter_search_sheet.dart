import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/location.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/service_provider.dart';

class FilterSearchSheet extends ConsumerStatefulWidget {
  final Function(LatLng)? onLocationSelected;
  final VoidCallback? onSearchCompleted;

  const FilterSearchSheet({
    super.key,
    this.onLocationSelected,
    this.onSearchCompleted,
  });

  @override
  ConsumerState<FilterSearchSheet> createState() => _FilterSearchSheetState();
}

class _FilterSearchSheetState extends ConsumerState<FilterSearchSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Category _selectedCategory = Category.general;
  final List<Category> _selectedCategories = [];
  String _searchQuery = '';
  LatLng? _selectedPosition;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(
        children: [
          // Header area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Draggable handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // Search field
                TextField(
                  controller: TextEditingController(text: _searchQuery),
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
                  onSubmitted: (_) {
                    _handleSearch();
                  },
                ),
                const SizedBox(height: 16),
                // Category filters
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Category.values.map((category) {
                    final isSelected = _selectedCategories.contains(category);
                    return FilterChip(
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
                      },
                      backgroundColor: theme.colorScheme.surface,
                      selectedColor: _getCategoryColor(category),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // Form content
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                controller: controller,
                children: [
                  // Location name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome *',
                      hintText: 'Nome del luogo',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nome obbligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descrizione',
                      hintText: 'Descrivi il luogo...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category dropdown
                  DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoria principale',
                    ),
                    items: Category.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Position display
                  ListTile(
                    title: const Text('Posizione selezionata'),
                    subtitle: Text(
                      _selectedPosition != null
                          ? '${_selectedPosition!.latitude.toStringAsFixed(5)}, ${_selectedPosition!.longitude.toStringAsFixed(5)}'
                          : 'Nessuna posizione selezionata',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.gps_fixed),
                          onPressed: _getCurrentLocation,
                          tooltip: 'Posizione corrente',
                        ),
                        if (_selectedPosition != null)
                          IconButton(
                            icon: const Icon(Icons.map),
                            onPressed: () => _showMapSelection(context),
                            tooltip: 'Seleziona sulla mappa',
                          ),
                      ],
                    ),
                  ),
                  // Preview map
                  if (_selectedPosition != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: _selectedPosition!,
                            initialZoom: 15.0,
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
                                  point: _selectedPosition!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Submit button
                  ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitLocation(context, isAuthenticated),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_location),
                    label: Text(
                      _isSubmitting
                          ? 'Salvataggio...'
                          : (isAuthenticated ? 'Aggiungi Luogo' : 'Accedi per aggiungere'),
                    ),
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: theme.colorScheme.onSurface.withOpacity(0.12),
                      disabledForegroundColor: theme.colorScheme.onSurface.withOpacity(0.38),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Seleziona una posizione sulla mappa o usa la tua posizione corrente per aggiungere un luogo.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSearch() async {
    if (_searchQuery.isEmpty) {
      ref.invalidate(locationsProvider);
      return;
    }

    try {
      final locations = await ref.read(mapServiceProvider).searchPlaces(_searchQuery);
      if (mounted) {
        // Show search results as markers on the map (hidden by default, toggle with button)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trovati ${locations.length} luoghi per "$_searchQuery"'),
            action: SnackBarAction(
              label: 'Mappa',
              textColor: Theme.of(context).colorScheme.primary,
              onPressed: () {
                // Handle map view of search results
              },
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nella ricerca')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final mapService = ref.read(mapServiceProvider);
      final hasPermission = await mapService.checkLocationPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permessi di localizzazione negati')),
        );
        return;
      }
      final position = await mapService.getCurrentLocation();
      setState(() => _selectedPosition = position);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore posizione: $e')),
        );
      }
    }
  }

  void _showMapSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MapSelectionSheet(
        initialPosition: _selectedPosition,
        onPositionSelected: (position) {
          setState(() => _selectedPosition = position);
        },
      ),
    );
  }

  Future<void> _submitLocation(BuildContext context, bool isAuthenticated) async {
    if (!_formKey.currentState!.validate()) return;

    if (!isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devi effettuare l\'accesso per aggiungere luoghi')),
      );
      return;
    }

    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona una posizione')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(supabaseServiceProvider).currentUser;
      if (user == null) throw Exception('Utente non autenticato');

      final location = Location(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        lat: _selectedPosition!.latitude,
        lng: _selectedPosition!.longitude,
        category: _selectedCategory,
        isVerified: false,
        createdAt: DateTime.now(),
        userId: user.id,
      );

      await ref.read(locationNotifierProvider.notifier).addLocation(location);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Luogo aggiunto con successo')),
        );
        Navigator.of(context).pop();
        widget.onSearchCompleted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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

class _MapSelectionSheet extends ConsumerStatefulWidget {
  final LatLng? initialPosition;
  final Function(LatLng) onPositionSelected;

  const _MapSelectionSheet({
    required this.initialPosition,
    required this.onPositionSelected,
  });

  @override
  ConsumerState<_MapSelectionSheet> createState() => _MapSelectionSheetState();
}

class _MapSelectionSheetState extends ConsumerState<_MapSelectionSheet> {
  LatLng? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition ?? const LatLng(41.9028, 12.4964);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Seleziona Posizione',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedPosition!.latitude.toStringAsFixed(5)}, ${_selectedPosition!.longitude.toStringAsFixed(5)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Map
          Expanded(
            child: FlutterMap(
              mapController: MapController(),
              options: MapOptions(
                initialCenter: _selectedPosition!,
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
                      point: _selectedPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outline, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _useCurrentPosition,
                    icon: const Icon(Icons.gps_fixed),
                    label: const Text('Posizione corrente'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onPositionSelected(_selectedPosition!);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Conferma'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useCurrentPosition() async {
    try {
      final mapService = ref.read(mapServiceProvider);
      final hasPermission = await mapService.checkLocationPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permessi di localizzazione negati')),
        );
        return;
      }
      final position = await mapService.getCurrentLocation();
      setState(() => _selectedPosition = position);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore posizione: $e')),
        );
      }
    }
  }
}
