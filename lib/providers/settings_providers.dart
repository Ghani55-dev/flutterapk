import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core_providers.dart';
import '../features/settings/settings_notifier.dart';

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) => SettingsNotifier(storage: ref.read(secureStorageProvider)));
