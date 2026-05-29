import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_enum.dart';
import '../services/adhan_player_service.dart';

const _kEnabled = 'adhan_enabled';
const _kChoice = 'adhan_choice';
const _kMutedPrefix = 'adhan_muted_';

class AdhanSettings {
  final bool enabled;
  final String choiceId;
  final Map<Prayer, bool> mutedPerPrayer;
  const AdhanSettings({
    required this.enabled,
    required this.choiceId,
    required this.mutedPerPrayer,
  });

  bool isMuted(Prayer p) => mutedPerPrayer[p] ?? false;

  AdhanChoice get choice => AdhanPlayerService.byId(choiceId);

  AdhanSettings copyWith({
    bool? enabled,
    String? choiceId,
    Map<Prayer, bool>? mutedPerPrayer,
  }) =>
      AdhanSettings(
        enabled: enabled ?? this.enabled,
        choiceId: choiceId ?? this.choiceId,
        mutedPerPrayer: mutedPerPrayer ?? this.mutedPerPrayer,
      );
}

class AdhanSettingsController extends StateNotifier<AdhanSettings> {
  AdhanSettingsController()
      : super(AdhanSettings(
          enabled: false,
          choiceId: 'system',
          mutedPerPrayer: {for (final p in Prayer.all) p: false},
        )) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AdhanSettings(
      enabled: prefs.getBool(_kEnabled) ?? false,
      choiceId: prefs.getString(_kChoice) ?? 'system',
      mutedPerPrayer: {
        for (final p in Prayer.all)
          p: prefs.getBool('$_kMutedPrefix${p.name}') ?? false,
      },
    );
  }

  Future<void> setEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, v);
    state = state.copyWith(enabled: v);
  }

  Future<void> setChoice(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kChoice, id);
    state = state.copyWith(choiceId: id);
  }

  Future<void> setMuted(Prayer p, bool muted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kMutedPrefix${p.name}', muted);
    final next = Map<Prayer, bool>.from(state.mutedPerPrayer);
    next[p] = muted;
    state = state.copyWith(mutedPerPrayer: next);
  }
}

final adhanSettingsProvider =
    StateNotifierProvider<AdhanSettingsController, AdhanSettings>(
        (_) => AdhanSettingsController());
