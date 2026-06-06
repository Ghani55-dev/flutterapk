import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/profile_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../location/location_provider.dart';

class ProfilePreferencesScreen extends ConsumerStatefulWidget {
  const ProfilePreferencesScreen({super.key});

  @override
  ConsumerState<ProfilePreferencesScreen> createState() => _ProfilePreferencesScreenState();
}

class _ProfilePreferencesScreenState extends ConsumerState<ProfilePreferencesScreen> {
  final _stateCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  String _language = 'en';
  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 16;
  bool _seeded = false;

  @override
  void dispose() {
    _stateCtrl.dispose();
    _districtCtrl.dispose();
    _villageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final location = ref.watch(locationProvider).valueOrNull;
    if (!_seeded) {
      _seeded = true;
      _language = settings.language;
      _themeMode = settings.themeMode;
      _fontSize = settings.fontSize;
      _stateCtrl.text = location?['state'] ?? '';
      _districtCtrl.text = location?['district'] ?? '';
      _villageCtrl.text = location?['village'] ?? location?['city'] ?? '';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          DropdownButtonFormField<String>(
            value: _language,
            decoration: const InputDecoration(labelText: 'Language'),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'hi', child: Text('Hindi')),
              DropdownMenuItem(value: 'te', child: Text('Telugu')),
              DropdownMenuItem(value: 'ta', child: Text('Tamil')),
              DropdownMenuItem(value: 'ar', child: Text('Arabic')),
              DropdownMenuItem(value: 'ur', child: Text('Urdu')),
            ],
            onChanged: (value) => setState(() => _language = value ?? _language),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ThemeMode>(
            value: _themeMode,
            decoration: const InputDecoration(labelText: 'Theme'),
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
            onChanged: (value) => setState(() => _themeMode = value ?? _themeMode),
          ),
          const SizedBox(height: 18),
          Text('Font Size: ${_fontSize.round()}', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          Slider(value: _fontSize, min: 14, max: 22, divisions: 8, label: _fontSize.round().toString(), onChanged: (value) => setState(() => _fontSize = value)),
          const SizedBox(height: 18),
          Text('Location', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          TextField(controller: _stateCtrl, decoration: const InputDecoration(labelText: 'State')),
          const SizedBox(height: 12),
          TextField(controller: _districtCtrl, decoration: const InputDecoration(labelText: 'District')),
          const SizedBox(height: 12),
          TextField(controller: _villageCtrl, decoration: const InputDecoration(labelText: 'Village / City')),
          if (profileState.error != null) ...[
            const SizedBox(height: 10),
            Text(profileState.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: profileState.saving ? null : _save,
            child: profileState.saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Preferences'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final location = {
      'state': _stateCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'village': _villageCtrl.text.trim(),
    };
    await ref.read(settingsNotifierProvider.notifier).setLanguage(_language);
    await ref.read(settingsNotifierProvider.notifier).setTheme(_themeMode);
    await ref.read(settingsNotifierProvider.notifier).setFontSize(_fontSize);
    await ref.read(locationProvider.notifier).saveManual(Map<String, String>.from(location));
    await ref.read(profileNotifierProvider.notifier).updateProfileAndLocation(
      {
        'preferred_language': _language,
        'theme': _themeMode.name,
        'font_size': _fontSize.round(),
      },
      location,
    );
    if (mounted && ref.read(profileNotifierProvider).error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences saved')));
    }
  }
}
