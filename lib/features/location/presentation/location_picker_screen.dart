import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/location_service.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  final _country = TextEditingController();
  final _state = TextEditingController();
  final _district = TextEditingController();
  final _city = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _country.dispose();
    _state.dispose();
    _district.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _useGps() async {
    setState(() => _saving = true);
    final svc = LocationService();
    final pos = await svc.getCurrentLocation();
    if (pos != null) {
      final map = await svc.reverseGeocode(pos);
      if (map != null) {
        _country.text = map['country'] ?? '';
        _state.text = map['state'] ?? '';
        _district.text = map['district'] ?? '';
        _city.text = map['city'] ?? '';
      }
    }
    setState(() => _saving = false);
  }

  Future<void> _saveManual() async {
    setState(() => _saving = true);
    final svc = LocationService();
    await svc.saveManualLocation({
      'country': _country.text,
      'state': _state.text,
      'district': _district.text,
      'city': _city.text,
    });
    setState(() => _saving = false);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select location')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(onPressed: _useGps, icon: const Icon(Icons.gps_fixed), label: const Text('Use current location')),
            const SizedBox(height: 12),
            TextField(controller: _country, decoration: const InputDecoration(labelText: 'Country')),
            TextField(controller: _state, decoration: const InputDecoration(labelText: 'State')),
            TextField(controller: _district, decoration: const InputDecoration(labelText: 'District')),
            TextField(controller: _city, decoration: const InputDecoration(labelText: 'City')),
            const Spacer(),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Not now'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: _saving ? null : _saveManual, child: _saving ? const CircularProgressIndicator() : const Text('Save'))),
              ],
            )
          ],
        ),
      ),
    );
  }
}
