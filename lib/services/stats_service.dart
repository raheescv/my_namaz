import '../models/prayer_enum.dart';
import '../models/prayer_record.dart';
import '../utils/date_utils.dart';

class StreakResult {
  final int current;
  final int longest;
  const StreakResult(this.current, this.longest);
}

class StatsService {
  StatsService._();

  /// Records keyed by yyyy-MM-dd for fast lookup.
  static Map<String, PrayerRecord> _byDate(List<PrayerRecord> rs) =>
      {for (final r in rs) DateX.ymd(r.date): r};

  /// Streak of consecutive days where ALL 5 prayers were prayed.
  static StreakResult perfectStreaks(List<PrayerRecord> records) {
    if (records.isEmpty) return const StreakResult(0, 0);
    final map = _byDate(records);
    final sorted = records.map((r) => r.date).toList()..sort();
    final start = sorted.first;
    final end = DateTime.now();
    int current = 0, longest = 0, run = 0;
    for (final d in DateX.rangeInclusive(start, end)) {
      final r = map[DateX.ymd(d)];
      if (r != null && r.isPerfect) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 0;
      }
    }
    // Current = run ending at today (or yesterday if today not logged)
    for (int i = 0;; i++) {
      final d = DateTime(end.year, end.month, end.day - i);
      final r = map[DateX.ymd(d)];
      if (r != null && r.isPerfect) {
        current++;
      } else {
        break;
      }
    }
    return StreakResult(current, longest);
  }

  /// Per-prayer completion percentage over the given records.
  static Map<Prayer, double> perPrayerRate(List<PrayerRecord> records) {
    if (records.isEmpty) return {for (final p in Prayer.all) p: 0.0};
    final counts = {for (final p in Prayer.all) p: 0};
    for (final r in records) {
      for (final p in Prayer.all) {
        if (r.isCompleted(p)) counts[p] = counts[p]! + 1;
      }
    }
    return {
      for (final p in Prayer.all) p: counts[p]! / records.length,
    };
  }

  static int totalCompleted(List<PrayerRecord> rs) =>
      rs.fold(0, (a, r) => a + r.completedCount);
  static int totalMissed(List<PrayerRecord> rs) =>
      rs.fold(0, (a, r) => a + (5 - r.completedCount));

  /// 0-100 score based on completed prayers over the last 30 days.
  static int consistencyScore(List<PrayerRecord> last30) {
    if (last30.isEmpty) return 0;
    const possible = 30 * 5;
    final done = totalCompleted(last30);
    return ((done / possible) * 100).round().clamp(0, 100);
  }

  /// Day-of-week completion rates (Mon=1..Sun=7).
  static Map<int, double> dayOfWeekRate(List<PrayerRecord> records) {
    final perDayDone = <int, int>{};
    final perDayPossible = <int, int>{};
    for (final r in records) {
      final w = r.date.weekday;
      perDayDone[w] = (perDayDone[w] ?? 0) + r.completedCount;
      perDayPossible[w] = (perDayPossible[w] ?? 0) + 5;
    }
    return {
      for (var w = 1; w <= 7; w++)
        w: (perDayPossible[w] ?? 0) == 0
            ? 0.0
            : perDayDone[w]! / perDayPossible[w]!,
    };
  }

  /// All missed prayer instances chronologically.
  static List<(DateTime, Prayer)> missedList(List<PrayerRecord> records) {
    final out = <(DateTime, Prayer)>[];
    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
    for (final r in sorted) {
      for (final p in Prayer.all) {
        if (!r.isCompleted(p)) out.add((r.date, p));
      }
    }
    return out;
  }
}
