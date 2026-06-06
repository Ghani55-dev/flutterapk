import 'package:state_notifier/state_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/secure_storage_interface.dart';
import 'package:flutter/material.dart';

class SettingsState {
  final ThemeMode themeMode;
  final String language;
  final bool notificationsEnabled;
  final double fontSize;

  SettingsState({this.themeMode = ThemeMode.system, this.language = 'en', this.notificationsEnabled = true, this.fontSize = 16});

  SettingsState copyWith({ThemeMode? themeMode, String? language, bool? notificationsEnabled, double? fontSize}) =>
      SettingsState(themeMode: themeMode ?? this.themeMode, language: language ?? this.language, notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled, fontSize: fontSize ?? this.fontSize);
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SecureStorageInterface storage;
  SettingsNotifier({required this.storage}) : super(SettingsState()) {
    _load();
  }

  static const _themeKey = 'pref_theme';
  static const _langKey = 'pref_lang';
  static const _notifKey = 'pref_notif';
  static const _fontSizeKey = 'pref_font_size';

  Future<void> _load() async {
    final t = await storage.read(_themeKey);
    final l = await storage.read(_langKey);
    final n = await storage.read(_notifKey);
    final f = await storage.read(_fontSizeKey);
    ThemeMode tm = ThemeMode.system;
    if (t == 'light') tm = ThemeMode.light;
    if (t == 'dark') tm = ThemeMode.dark;
    state = state.copyWith(themeMode: tm, language: l ?? state.language, notificationsEnabled: n != '0', fontSize: double.tryParse(f ?? '') ?? state.fontSize);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final v = mode == ThemeMode.light ? 'light' : mode == ThemeMode.dark ? 'dark' : 'system';
    await storage.write(_themeKey, v);
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    await storage.write(_langKey, lang);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await storage.write(_notifKey, enabled ? '1' : '0');
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await storage.write(_fontSizeKey, size.toStringAsFixed(0));
  }
}
