import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location.dart';
import '../models/review.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/review_provider.dart';
import '../widgets/image_uploader.dart';

class AddReviewScreen extends ConsumerStatefulWidget {
  final String locationId;

  const AddReviewScreen({
    super.key,
    required this.locationId,
  });

  @override
  ConsumerState<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends ConsumerState<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  int _rating = 3;
  final _reviewTextController = TextEditingController();
  final _categoryDetailController = TextEditingController();
  bool _isAnonymous = true;
  bool _hasVisited = false;
  bool _isHealthcare = false;
  int _cleanliness = 3;
  int _personalAttention = 3;
  int _waitingTime = 3;
  final List<String> _images = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkCategory();
  }

  Future<void> _checkCategory() async {
    final locationAsync = ref.read(locationByIdProvider(widget.locationId));
    locationAsync.whenOrNull(
      data: (location) {
        if (location != null && mounted) {
          setState(() => _isHealthcare = location.category == Category.healthcare);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Aggiungi Recensione')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Valutazione', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reviewTextController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Recensione',
                hintText: 'Descrivi la tua esperienza...',
              ),
            ),
            if (_isHealthcare) ...[
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Ho visitato questo luogo'),
                subtitle: const Text(
                  'Disclaimer legale: confermo di aver visitato personalmente questa struttura sanitaria',
                ),
                value: _hasVisited,
                onChanged: (value) => setState(() => _hasVisited = value ?? false),
              ),
              if (_hasVisited) ...[
                const SizedBox(height: 16),
                Text('Valutazioni specifiche', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildHealthcareRating('Pulizia', _cleanliness, (v) => setState(() => _cleanliness = v)),
                _buildHealthcareRating('Attenzione Personale', _personalAttention, (v) => setState(() => _personalAttention = v)),
                _buildHealthcareRating('Tempo di Attesa', _waitingTime, (v) => setState(() => _waitingTime = v)),
              ],
            ],
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Anonimizza'),
              value: _isAnonymous,
              onChanged: (value) => setState(() => _isAnonymous = value ?? true),
            ),
            const SizedBox(height: 16),
            ImageUploader(
              onImagesSelected: (urls) => setState(() => _images.addAll(urls)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Invia Recensione'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthcareRating(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < value ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  ),
                  onPressed: () => onChanged(index + 1),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isHealthcare && !_hasVisited) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devi confermare di aver visitato il luogo')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(supabaseServiceProvider).currentUser;
      if (user == null) throw Exception('Utente non autenticato');

      final categoryDetail = _isHealthcare && _hasVisited
          ? 'Pulizia: $_cleanliness, Attenzione: $_personalAttention, Attesa: $_waitingTime'
          : (_categoryDetailController.text.isNotEmpty ? _categoryDetailController.text : null);

      final review = Review(
        id: '',
        locationId: widget.locationId,
        rating: _rating,
        reviewText: _reviewTextController.text.isNotEmpty ? _reviewTextController.text : null,
        categoryDetail: categoryDetail,
        images: _images,
        isAnonymous: _isAnonymous,
        createdAt: DateTime.now(),
      );

      await ref.read(reviewNotifierProvider.notifier).addReview(widget.locationId, review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recensione aggiunta con successo')),
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
    _reviewTextController.dispose();
    _categoryDetailController.dispose();
    super.dispose();
  }
}
