import 'package:adhan/adhan.dart' as adhan;

import '../models/prayer_enum.dart';

/// One calendar day of prayer times for a specific location.
class DailyPrayerTimes {
  final DateTime date;
  final Map<Prayer, DateTime> times;
  final DateTime sunrise;
  final adhan.CalculationMethod method;
  final adhan.Madhab madhab;
  final double latitude;
  final double longitude;

  const DailyPrayerTimes({
    required this.date,
    required this.times,
    required this.sunrise,
    required this.method,
    required this.madhab,
    required this.latitude,
    required this.longitude,
  });

  /// Next upcoming prayer at the given moment, or null if Isha has passed.
  ({Prayer prayer, DateTime at})? next(DateTime now) {
    for (final p in Prayer.all) {
      final t = times[p];
      if (t != null && t.isAfter(now)) return (prayer: p, at: t);
    }
    return null;
  }

  /// Prayer currently in window (i.e. last prayer whose time has started),
  /// or null if Fajr hasn't started yet.
  Prayer? current(DateTime now) {
    Prayer? cur;
    for (final p in Prayer.all) {
      final t = times[p];
      if (t != null && !t.isAfter(now)) cur = p;
    }
    return cur;
  }
}

class PrayerTimesService {
  PrayerTimesService._();

  static DailyPrayerTimes compute({
    required double latitude,
    required double longitude,
    required DateTime date,
    adhan.CalculationMethod method =
        adhan.CalculationMethod.muslim_world_league,
    adhan.Madhab madhab = adhan.Madhab.shafi,
  }) {
    final coords = adhan.Coordinates(latitude, longitude);
    final params = method.getParameters()..madhab = madhab;
    final dc = adhan.DateComponents(date.year, date.month, date.day);
    final pt = adhan.PrayerTimes(coords, dc, params);

    return DailyPrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      sunrise: pt.sunrise,
      times: {
        Prayer.fajr: pt.fajr,
        Prayer.dhuhr: pt.dhuhr,
        Prayer.asr: pt.asr,
        Prayer.maghrib: pt.maghrib,
        Prayer.isha: pt.isha,
      },
      method: method,
      madhab: madhab,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Human-readable label for each calculation method.
  static String methodLabel(adhan.CalculationMethod m) {
    switch (m) {
      case adhan.CalculationMethod.muslim_world_league:
        return 'Muslim World League';
      case adhan.CalculationMethod.egyptian:
        return 'Egyptian General Authority';
      case adhan.CalculationMethod.karachi:
        return 'University of Islamic Sciences, Karachi';
      case adhan.CalculationMethod.umm_al_qura:
        return 'Umm al-Qura, Makkah';
      case adhan.CalculationMethod.dubai:
        return 'Dubai';
      case adhan.CalculationMethod.moon_sighting_committee:
        return 'Moon Sighting Committee';
      case adhan.CalculationMethod.north_america:
        return 'ISNA (North America)';
      case adhan.CalculationMethod.kuwait:
        return 'Kuwait';
      case adhan.CalculationMethod.qatar:
        return 'Qatar';
      case adhan.CalculationMethod.singapore:
        return 'Singapore';
      case adhan.CalculationMethod.turkey:
        return 'Turkey (Diyanet)';
      case adhan.CalculationMethod.tehran:
        return 'Tehran';
      case adhan.CalculationMethod.other:
        return 'Custom';
    }
  }

  static String madhabLabel(adhan.Madhab m) =>
      m == adhan.Madhab.hanafi ? 'Hanafi' : 'Shafi / Maliki / Hanbali';
}
