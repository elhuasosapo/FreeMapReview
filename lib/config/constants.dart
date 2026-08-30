import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class AppConstants {
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_PUBLISHABLE_KEY';
  static const String appName = 'Free Map Review';
  static const String storageBucket = 'location-images';

  static const LatLng defaultCenter = LatLng(41.9028, 12.4964);
  static const double defaultZoom = 13.0;

  static const Duration apiTimeout = Duration(seconds: 30);

  static bool get isWeb => kIsWeb;
}
