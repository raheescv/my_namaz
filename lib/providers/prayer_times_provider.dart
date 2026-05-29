import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/prayer_times_service.dart';
import 'prayer_provider.dart';

enum LocationMode { automatic, manual }

class StoredLocation {
  final double latitude;
  final double longitude;
  final String? city;
  final DateTime fetchedAt;
  final LocationMode mode;
  const StoredLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    required this.fetchedAt,
    this.mode = LocationMode.automatic,
  });
}

const _kLat = 'loc_lat';
const _kLon = 'loc_lon';
const _kCity = 'loc_city';
const _kFetched = 'loc_fetched';
const _kMode = 'loc_mode';
const _kCalcMethod = 'prayer_calc_method';
const _kMadhab = 'prayer_madhab';

class LocationController extends StateNotifier<AsyncValue<StoredLocation?>> {
  LocationController() : super(const AsyncValue.loading()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_kLat);
    final lon = prefs.getDouble(_kLon);
    final city = prefs.getString(_kCity);
    final fetched = prefs.getInt(_kFetched);
    final mode = prefs.getString(_kMode) == 'manual'
        ? LocationMode.manual
        : LocationMode.automatic;
    if (lat != null && lon != null && fetched != null) {
      state = AsyncValue.data(StoredLocation(
        latitude: lat,
        longitude: lon,
        city: city,
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(fetched),
        mode: mode,
      ));
    } else {
      state = const AsyncValue.data(null);
    }
  }

  /// Re-acquire location from GPS, with city reverse-geocoded.
  /// Returns null if permission denied or service off.
  Future<StoredLocation?> refresh() async {
    state = const AsyncValue.loading();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        state = AsyncValue.error(
            'Location services are off', StackTrace.current);
        return null;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        state = AsyncValue.error(
            'Location permission denied', StackTrace.current);
        return null;
      }
      final pos = await Geolocator.getCurrentPosition();
      String? city;
      try {
        final marks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          final p = marks.first;
          city = [p.locality, p.administrativeArea, p.country]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
        }
      } catch (_) {}

      final loc = StoredLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        city: city,
        fetchedAt: DateTime.now(),
        mode: LocationMode.automatic,
      );
      await _persist(loc);
      state = AsyncValue.data(loc);
      return loc;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Toggle between automatic (GPS) and manual (user-picked) modes.
  /// Turning Automatic ON immediately re-fetches GPS.
  /// Turning OFF keeps the current coordinates but marks the mode as manual.
  Future<void> setAutomatic(bool automatic) async {
    final cur = state.value;
    if (automatic) {
      await refresh();
    } else {
      if (cur != null) {
        final next = StoredLocation(
          latitude: cur.latitude,
          longitude: cur.longitude,
          city: cur.city,
          fetchedAt: cur.fetchedAt,
          mode: LocationMode.manual,
        );
        await _persist(next);
        state = AsyncValue.data(next);
      } else {
        // No prior location — just flip the mode in prefs so the next
        // manual pick is stored correctly.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kMode, 'manual');
      }
    }
  }

  /// Apply a user-picked location (manual mode).
  Future<void> setManualLocation({
    required double latitude,
    required double longitude,
    String? city,
  }) async {
    final loc = StoredLocation(
      latitude: latitude,
      longitude: longitude,
      city: city,
      fetchedAt: DateTime.now(),
      mode: LocationMode.manual,
    );
    await _persist(loc);
    state = AsyncValue.data(loc);
  }

  Future<void> _persist(StoredLocation loc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLat, loc.latitude);
    await prefs.setDouble(_kLon, loc.longitude);
    if (loc.city != null) {
      await prefs.setString(_kCity, loc.city!);
    } else {
      await prefs.remove(_kCity);
    }
    await prefs.setInt(_kFetched, loc.fetchedAt.millisecondsSinceEpoch);
    await prefs.setString(_kMode,
        loc.mode == LocationMode.manual ? 'manual' : 'automatic');
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLat);
    await prefs.remove(_kLon);
    await prefs.remove(_kCity);
    await prefs.remove(_kFetched);
    await prefs.remove(_kMode);
    state = const AsyncValue.data(null);
  }
}

final locationProvider =
    StateNotifierProvider<LocationController, AsyncValue<StoredLocation?>>(
        (_) => LocationController());

// ---- Calculation method + madhab persisted in prefs ----

class CalcSettings {
  final adhan.CalculationMethod method;
  final adhan.Madhab madhab;
  const CalcSettings({required this.method, required this.madhab});
  CalcSettings copyWith({
    adhan.CalculationMethod? method,
    adhan.Madhab? madhab,
  }) =>
      CalcSettings(
        method: method ?? this.method,
        madhab: madhab ?? this.madhab,
      );
}

class CalcSettingsController extends StateNotifier<CalcSettings> {
  CalcSettingsController()
      : super(const CalcSettings(
            method: adhan.CalculationMethod.muslim_world_league,
            madhab: adhan.Madhab.shafi)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final m = prefs.getString(_kCalcMethod);
    final h = prefs.getString(_kMadhab);
    state = CalcSettings(
      method: _methodFrom(m) ?? state.method,
      madhab: h == 'hanafi' ? adhan.Madhab.hanafi : adhan.Madhab.shafi,
    );
  }

  Future<void> setMethod(adhan.CalculationMethod m) async {
    state = state.copyWith(method: m);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCalcMethod, m.name);
  }

  Future<void> setMadhab(adhan.Madhab m) async {
    state = state.copyWith(madhab: m);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMadhab, m == adhan.Madhab.hanafi ? 'hanafi' : 'shafi');
  }

  adhan.CalculationMethod? _methodFrom(String? s) {
    if (s == null) return null;
    for (final v in adhan.CalculationMethod.values) {
      if (v.name == s) return v;
    }
    return null;
  }
}

final calcSettingsProvider =
    StateNotifierProvider<CalcSettingsController, CalcSettings>(
        (_) => CalcSettingsController());

// ---- Prayer times for the currently-selected date + current location ----

final dailyPrayerTimesProvider = Provider<DailyPrayerTimes?>((ref) {
  final loc = ref.watch(locationProvider).value;
  final date = ref.watch(selectedDateProvider);
  final calc = ref.watch(calcSettingsProvider);
  if (loc == null) return null;
  return PrayerTimesService.compute(
    latitude: loc.latitude,
    longitude: loc.longitude,
    date: date,
    method: calc.method,
    madhab: calc.madhab,
  );
});
