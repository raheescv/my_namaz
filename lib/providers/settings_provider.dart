import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

class AppSettings {
  final ThemeMode themeMode;
  final Locale locale;
  final bool hijriEnabled;
  final bool remindersEnabled;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
    this.hijriEnabled = true,
    this.remindersEnabled = false,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? hijriEnabled,
    bool? remindersEnabled,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        hijriEnabled: hijriEnabled ?? this.hijriEnabled,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      );
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = AppSettings(
      themeMode: _themeFromString(p.getString(K.prefsThemeMode)),
      locale: Locale(p.getString(K.prefsLocale) ?? 'en'),
      hijriEnabled: p.getBool(K.prefsHijriEnabled) ?? true,
      remindersEnabled: p.getBool(K.prefsRemindersEnabled) ?? false,
    );
  }

  Future<void> setThemeMode(ThemeMode m) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(K.prefsThemeMode, m.name);
    state = state.copyWith(themeMode: m);
  }

  Future<void> setLocale(Locale l) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(K.prefsLocale, l.languageCode);
    state = state.copyWith(locale: l);
  }

  Future<void> setHijri(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(K.prefsHijriEnabled, v);
    state = state.copyWith(hijriEnabled: v);
  }

  Future<void> setReminders(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(K.prefsRemindersEnabled, v);
    state = state.copyWith(remindersEnabled: v);
  }

  ThemeMode _themeFromString(String? s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsController, AppSettings>(
        (ref) => SettingsController());
