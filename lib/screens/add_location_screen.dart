import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/location.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/service_provider.dart';

class AddLocationScreen extends ConsumerStatefulWidget {
  final LatLng? initialPosition;

  const AddLocationScreen({super.key, this.initialPosition});

  @override
  ConsumerState<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends ConsumerState<AddLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Category _selectedCategory = Category.general;
  LatLng? _selectedPosition;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _reverseGeocode();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo Luogo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                hintText: 'Nome del luogo',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Nome obbligatorio';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrizione',
                hintText: 'Descrivi il luogo...',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Category>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: Category.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Posizione'),
              subtitle: Text(_selectedPosition != null
                  ? '${_selectedPosition!.latitude.toStringAsFixed(5)}, ${_selectedPosition!.longitude.toStringAsFixed(5)}'
                  : 'Nessuna posizione selezionata'),
              trailing: IconButton(
                icon: const Icon(Icons.gps_fixed),
                onPressed: _getCurrentLocation,
              ),
            ),
            if (_selectedPosition != null)
              Container(
                height: 200,
                margin: const EdgeInsets.only(bottom: 16),
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
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
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
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.gps_fixed),
              label: const Text('Usa Posizione Corrente'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitLocation,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Aggiungi Luogo'),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _reverseGeocode() async {
    if (_selectedPosition == null) return;
    try {
      final mapService = ref.read(mapServiceProvider);
      final address = await mapService.getAddressFromLatLng(_selectedPosition!);
      if (mounted && _nameController.text.isEmpty) {
        setState(() => _nameController.text = address);
      }
    } catch (_) {}
  }

  Future<void> _submitLocation() async {
    if (!_formKey.currentState!.validate()) return;
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
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
