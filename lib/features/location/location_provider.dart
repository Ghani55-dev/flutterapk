import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/location_service.dart';

final locationProvider = StateNotifierProvider<LocationNotifier, AsyncValue<Map<String, String>?>>(
  (ref) => LocationNotifier(),
);

class LocationNotifier extends StateNotifier<AsyncValue<Map<String, String>?>> {
  LocationNotifier() : super(const AsyncValue.loading()) {
    _loadSaved();
  }

  final _svc = LocationService();

  Future<void> _loadSaved() async {
    final saved = await _svc.loadSavedLocation();
    state = AsyncValue.data(saved);
  }

  Future<void> refreshFromGps() async {
    state = const AsyncValue.loading();
    final pos = await _svc.getCurrentLocation();
    if (pos == null) {
      state = const AsyncValue.data(null);
      return;
    }
    final map = await _svc.reverseGeocode(pos);
    if (map != null) {
      await _svc.saveManualLocation(map);
    }
    state = AsyncValue.data(map);
  }

  Future<void> saveManual(Map<String, String> map) async {
    await _svc.saveManualLocation(map);
    state = AsyncValue.data(map);
  }
}
