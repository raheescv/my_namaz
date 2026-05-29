import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// One adhan recitation that the user can choose from.
class AdhanChoice {
  final String id; // stable key used in prefs
  final String label;
  final String? assetPath; // null = use platform default notification sound
  final String? reciter;

  const AdhanChoice({
    required this.id,
    required this.label,
    this.assetPath,
    this.reciter,
  });
}

/// Singleton service that plays adhan audio inside the app (foreground).
///
/// Background scheduling at exact prayer times is handled by
/// [NotificationService] which uses the OS's notification sound channel —
/// see notes there about iOS' 30s limit.
class AdhanPlayerService {
  AdhanPlayerService._();
  static final AdhanPlayerService instance = AdhanPlayerService._();

  static const List<AdhanChoice> availableAdhans = [
    AdhanChoice(
      id: 'system',
      label: 'System default sound',
      assetPath: null,
    ),
    AdhanChoice(
      id: 'makkah',
      label: 'Adhan from Makkah',
      assetPath: 'assets/audio/adhan_makkah.mp3',
      reciter: 'Al-Masjid al-Haram',
    ),
    AdhanChoice(
      id: 'madinah',
      label: 'Adhan from Madinah',
      assetPath: 'assets/audio/adhan_madinah.mp3',
      reciter: 'Al-Masjid an-Nabawi',
    ),
    AdhanChoice(
      id: 'mishary',
      label: 'Mishary Rashid Alafasy',
      assetPath: 'assets/audio/adhan_mishary.mp3',
      reciter: 'Mishary Rashid Alafasy',
    ),
  ];

  static AdhanChoice byId(String id) =>
      availableAdhans.firstWhere((a) => a.id == id,
          orElse: () => availableAdhans.first);

  AudioPlayer? _player;
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('[adhan] audio session init: $e');
    }
    _player = AudioPlayer();
    _ready = true;
  }

  /// Play the given adhan. Returns true if playback started.
  /// Throws nothing — failures are logged.
  Future<bool> play(AdhanChoice choice) async {
    await _ensureReady();
    try {
      await _player?.stop();
      if (choice.assetPath == null) {
        // System default — we can't play the OS notification sound directly
        // from inside the app, so this is effectively a no-op for foreground.
        // The notification scheduler uses it at prayer time.
        debugPrint('[adhan] system default — no in-app playback');
        return false;
      }
      // assetPath includes the leading "assets/" — just_audio's setAsset
      // wants the path WITHOUT it.
      final asset = choice.assetPath!.startsWith('assets/')
          ? choice.assetPath!.substring('assets/'.length)
          : choice.assetPath!;
      await _player!.setAsset('assets/$asset');
      await _player!.play();
      return true;
    } catch (e, st) {
      debugPrint('[adhan] play failed: $e\n$st');
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
    _ready = false;
  }
}
