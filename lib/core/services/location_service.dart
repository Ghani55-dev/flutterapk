import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final _secure = const FlutterSecureStorage();
  static const _kSavedLocationKey = 'user_saved_location';

  Future<LocationPermission> checkLocationPermission() async {
    final perm = await Geolocator.checkPermission();
    debugPrint('LocationService.checkLocationPermission -> $perm');
    return perm;
  }

  Future<bool> checkLocationEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('LocationService.checkLocationEnabled -> $enabled');
    return enabled;
  }

  Future<LocationPermission> requestLocationPermission() async {
    final perm = await Geolocator.requestPermission();
    debugPrint('LocationService.requestLocationPermission -> $perm');
    return perm;
  }

  Future<Position?> getCurrentLocation({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService.getCurrentLocation: service disabled');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        debugPrint('LocationService.getCurrentLocation: permission not granted');
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: timeout);
      debugPrint('LocationService.getCurrentLocation -> $pos');
      return pos;
    } catch (e, st) {
      debugPrint('LocationService.getCurrentLocation ERROR: $e\n$st');
      return null;
    }
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
  Future<bool> launchAppSettings() => openAppSettings();

  /// Reverse-geocode coordinates to a locality map (country/state/city/district)
  Future<Map<String, String>?> reverseGeocode(Position pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      return {
        'country': p.country ?? '',
        'state': p.administrativeArea ?? '',
        'city': p.locality ?? '',
        'district': p.subLocality ?? '',
      };
    } catch (e, st) {
      debugPrint('LocationService.reverseGeocode ERROR: $e\n$st');
      return null;
    }
  }

  Future<void> saveManualLocation(Map<String, String> location) async {
    await _secure.write(key: _kSavedLocationKey, value: location.entries.map((e) => '${e.key}=${e.value}').join('&'));
  }

  Future<Map<String, String>?> loadSavedLocation() async {
    final raw = await _secure.read(key: _kSavedLocationKey);
    if (raw == null) return null;
    final result = <String, String>{};
    for (final part in raw.split('&')) {
      final idx = part.indexOf('=');
      if (idx <= 0) continue;
      final k = part.substring(0, idx);
      final v = part.substring(idx + 1);
      result[k] = v;
    }
    return result;
  }
}
