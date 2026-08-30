import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_service.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploader extends ConsumerStatefulWidget {
  final Function(List<String>) onImagesSelected;
  final int maxImages;

  const ImageUploader({
    super.key,
    required this.onImagesSelected,
    this.maxImages = 5,
  });

  @override
  ConsumerState<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends ConsumerState<ImageUploader> {
  final ImageService _imageService = ImageService(Supabase.instance.client);
  final List<File> _selectedImages = [];
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Massimo ${widget.maxImages} immagini')),
      );
      return;
    }

    final image = await _imageService.pickImage(source);
    if (image != null && mounted) {
      setState(() => _selectedImages.add(image));
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      final urls = await _imageService.uploadImages(_selectedImages);
      widget.onImagesSelected(urls);
      setState(() => _selectedImages.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Immagini caricate con successo')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore caricamento: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading
                  ? null
                  : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Fotocamera'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isUploading
                  ? null
                  : () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Galleria'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedImages.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_selectedImages.length, (index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImages[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      iconSize: 20,
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _removeImage(index),
                    ),
                  ),
                ],
              );
            }),
          ),
        const SizedBox(height: 12),
        if (_selectedImages.isNotEmpty)
          ElevatedButton(
            onPressed: _isUploading ? null : _uploadImages,
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Carica Immagini'),
          ),
      ],
    );
  }
}
