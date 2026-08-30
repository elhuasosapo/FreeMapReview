import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import '../models/location.dart';
import '../config/constants.dart';

class MapService {
  final nominatim = Nominatim(userAgent: AppConstants.appName);

  Future<List<Location>> searchPlaces(String query) async {
    try {
      final results = await nominatim.searchByName(
        query: query,
        limit: 20,
        addressDetails: true,
        language: 'it,en',
      );

      return results.map((r) => Location(
            id: r.placeId.toString(),
            name: r.displayName.split(',').first,
            description: r.displayName,
            lat: r.lat,
            lng: r.lon,
            category: Category.general,
            isVerified: false,
            createdAt: DateTime.now(),
            userId: '',
          )).toList();
    } on Exception catch (e) {
      throw Exception('Ricerca fallita: $e');
    }
  }

  Future<LatLng> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(position.latitude, position.longitude);
    } on Exception catch (e) {
      throw Exception('Posizione non disponibile: $e');
    }
  }

  Future<String> getAddressFromLatLng(LatLng latLng) async {
    try {
      final result = await nominatim.reverseSearch(
        lat: latLng.latitude,
        lon: latLng.longitude,
        addressDetails: true,
        language: 'it,en',
      );
      return result.displayName;
    } on Exception catch (_) {
      return 'Posizione sconosciuta';
    }
  }

  Stream<LatLng> getPositionStream() async* {
    final settings = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    yield LatLng(settings.latitude, settings.longitude);

    await for (final position
        in Geolocator.getPositionStream(locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ))) {
      yield LatLng(position.latitude, position.longitude);
    }
  }

  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }
}
