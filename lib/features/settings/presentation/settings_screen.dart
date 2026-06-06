import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(state.themeMode == ThemeMode.system ? 'System' : state.themeMode == ThemeMode.light ? 'Light' : 'Dark'),
            onTap: () async {
              final choice = await showDialog<ThemeMode>(context: context, builder: (c) => SimpleDialog(title: const Text('Select theme'), children: [SimpleDialogOption(onPressed: () => Navigator.pop(c, ThemeMode.system), child: const Text('System')), SimpleDialogOption(onPressed: () => Navigator.pop(c, ThemeMode.light), child: const Text('Light')), SimpleDialogOption(onPressed: () => Navigator.pop(c, ThemeMode.dark), child: const Text('Dark'))]));
              if (choice != null) await notifier.setTheme(choice);
            },
          ),
          SwitchListTile(title: const Text('Enable notifications'), value: state.notificationsEnabled, onChanged: (v) => notifier.setNotificationsEnabled(v)),
          ListTile(title: const Text('Language'), subtitle: Text(state.language), onTap: () async {
            final lang = await showDialog<String>(context: context, builder: (c) => SimpleDialog(title: const Text('Select language'), children: [SimpleDialogOption(onPressed: () => Navigator.pop(c, 'en'), child: const Text('English')), SimpleDialogOption(onPressed: () => Navigator.pop(c, 'es'), child: const Text('Spanish'))]));
            if (lang != null) await notifier.setLanguage(lang);
          }),
        ],
      ),
    );
  }
}
