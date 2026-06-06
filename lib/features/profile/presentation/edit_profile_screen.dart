import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/profile_providers.dart';
import '../../../providers/settings_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  String _language = 'en';
  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 16;
  bool _seeded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final profile = profileState.profile;
    if (!_seeded) {
      _seeded = true;
      _nameCtrl.text = profile?.displayName ?? '';
      _imageCtrl.text = profile?.avatarUrl ?? '';
      _language = profile?.preferredLanguage ?? settings.language;
      _themeMode = settings.themeMode;
      _fontSize = profile?.fontSize ?? settings.fontSize;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name'), validator: _required),
            const SizedBox(height: 12),
            TextFormField(controller: _imageCtrl, decoration: const InputDecoration(labelText: 'Profile Image URL')),
            const SizedBox(height: 12),
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
            if (profileState.error != null) ...[
              const SizedBox(height: 10),
              Text(profileState.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: profileState.saving ? null : _save,
              child: profileState.saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(settingsNotifierProvider.notifier).setLanguage(_language);
    await ref.read(settingsNotifierProvider.notifier).setTheme(_themeMode);
    await ref.read(settingsNotifierProvider.notifier).setFontSize(_fontSize);
    await ref.read(profileNotifierProvider.notifier).updateProfile({
      'full_name': _nameCtrl.text.trim(),
      'preferred_language': _language,
      'theme': _themeMode.name,
      'font_size': _fontSize.round(),
      if (_imageCtrl.text.trim().isNotEmpty) 'profile_image': _imageCtrl.text.trim(),
    });
    if (mounted && ref.read(profileNotifierProvider).error == null) context.pop();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
}
