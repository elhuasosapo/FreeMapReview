import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';

class ImageService {
  final SupabaseClient _supabase;

  ImageService(this._supabase);

  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (picked == null) return null;
    return File(picked.path);
  }

  Future<List<String>> uploadImages(List<File> images) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Utente non autenticato');

    final List<String> urls = [];

    for (final image in images) {
      final bytes = await image.readAsBytes();
      final compressed = await _compressImage(bytes);

      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';

      await _supabase.storage
          .from(AppConstants.storageBucket)
          .uploadBinary(fileName, compressed, fileOptions: const FileOptions(upsert: true));

      final publicUrl = _supabase.storage
          .from(AppConstants.storageBucket)
          .getPublicUrl(fileName);

      urls.add(publicUrl);
    }

    return urls;
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      final maxSize = 1024;
      int width = image.width;
      int height = image.height;

      if (width > height && width > maxSize) {
        height = (height * maxSize / width).round();
        width = maxSize;
      } else if (height > maxSize) {
        width = (width * maxSize / height).round();
        height = maxSize;
      }

      final resized = img.copyResize(image, width: width, height: height);
      return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
    } catch (_) {
      return bytes;
    }
  }

  Future<void> deleteImage(String publicUrl) async {
    try {
      final path = _extractPathFromUrl(publicUrl);
      await _supabase.storage
          .from(AppConstants.storageBucket)
          .remove([path]);
    } catch (_) {}
  }

  String _extractPathFromUrl(String publicUrl) {
    final uri = Uri.parse(publicUrl);
    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf('location-images');
    if (bucketIndex >= 0 && bucketIndex + 1 < segments.length) {
      return segments.sublist(bucketIndex + 1).join('/');
    }
    return publicUrl;
  }
}
