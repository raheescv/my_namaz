import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../models/prayer_enum.dart';
import '../providers/prayer_provider.dart';
import '../providers/prayer_times_provider.dart';
import '../providers/settings_provider.dart';
import '../services/prayer_times_service.dart';
import '../theme/colors.dart';
import '../utils/date_utils.dart';
import 'prayer_countdown_ring.dart';

class PrayerTimesCard extends ConsumerStatefulWidget {
  const PrayerTimesCard({super.key});
  @override
  ConsumerState<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends ConsumerState<PrayerTimesCard> {
  Timer? _ticker;
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _tick.value++;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = ref.watch(selectedDateProvider);

    // The card is only useful on today (countdown to next prayer).
    // For other dates the prayer cards below already show each time
    // next to the prayer name, so showing them here would be redundant.
    if (!DateX.isToday(date)) return const SizedBox.shrink();

    final locAsync = ref.watch(locationProvider);
    final daily = ref.watch(dailyPrayerTimesProvider);

    return locAsync.when(
      loading: () => _shell(theme,
          const SizedBox(
              height: 80,
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)))),
      error: (e, _) => _shell(theme, _error(theme, _short(e.toString()))),
      data: (loc) {
        if (loc == null) return _enableLocationPrompt(theme);
        if (daily == null) {
          return _shell(theme,
              const SizedBox(
                  height: 80,
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2))));
        }
        return _content(theme, daily, loc.city);
      },
    );
  }

  String _short(String s) =>
      s.length > 80 ? '${s.substring(0, 80)}…' : s;

  Widget _shell(ThemeData theme, Widget child) => Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surfaceContainerHigh,
              theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
            ],
          ),
          border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.08)),
        ),
        child: child,
      );

  Widget _enableLocationPrompt(ThemeData theme) => _shell(
        theme,
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.access_time_outlined,
                  color: AppColors.primaryGreen),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Show local prayer times',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            FilledButton(
              onPressed: () =>
                  ref.read(locationProvider.notifier).refresh(),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text('Enable'),
            ),
          ],
        ),
      );

  Widget _error(ThemeData theme, String message) => Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          TextButton(
            onPressed: () =>
                ref.read(locationProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      );

  Widget _content(
      ThemeData theme, DailyPrayerTimes daily, String? city) {
    final hijriOn = ref.watch(settingsProvider).hijriEnabled;
    return _shell(
      theme,
      Column(
        children: [
          if (hijriOn)
            Text(
              _hijriString(daily.date),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.accentGold,
                letterSpacing: -0.2,
              ),
            ),
          if (city != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                city,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 22),
          ValueListenableBuilder<int>(
            valueListenable: _tick,
            builder: (_, __, ___) => _countdown(daily),
          ),
        ],
      ),
    );
  }

  // ───────── COUNTDOWN (today only) ─────────

  Widget _countdown(DailyPrayerTimes daily) {
    final now = DateTime.now();
    final upcoming = daily.next(now);
    double progress = 0;
    String timeLeft = '';
    String prayerName = '—';
    String prayerTimeStr = '';
    Prayer? prayer;

    if (upcoming != null) {
      final from = _previousAnchor(daily, upcoming.prayer, now);
      final total = upcoming.at.difference(from).inSeconds;
      final elapsed = now.difference(from).inSeconds;
      progress = total <= 0 ? 0 : (elapsed / total).clamp(0.0, 1.0);
      timeLeft = _formatRemaining(upcoming.at.difference(now));
      prayerName = upcoming.prayer.name;
      prayerTimeStr = DateFormat('h:mm a').format(upcoming.at);
      prayer = upcoming.prayer;
    } else {
      // After Isha → countdown to tomorrow's Fajr (rough approximation).
      final tomorrow =
          daily.times[Prayer.fajr]!.add(const Duration(days: 1));
      final diff = tomorrow.difference(now);
      timeLeft = _formatRemaining(diff);
      prayerName = 'Fajr';
      prayer = Prayer.fajr;
      prayerTimeStr = DateFormat('h:mm a').format(tomorrow);
      progress = 1 -
          (diff.inSeconds /
                  const Duration(hours: 8).inSeconds.toDouble())
              .clamp(0.0, 1.0);
    }
    return PrayerCountdownRing(
      progress: progress,
      timeLeft: timeLeft,
      label: 'left until',
      prayerName: prayerName,
      prayerTime: prayerTimeStr,
      prayer: prayer,
      size: 230,
    );
  }

  // ───────── helpers ─────────

  String _formatRemaining(Duration d) {
    if (d.inMinutes < 1) {
      final s = d.inSeconds.abs();
      return '0:${s.toString().padLeft(2, '0')}';
    }
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h <= 0) return '${m}m';
    return '${h}h ${m}m';
  }

  DateTime _previousAnchor(
      DailyPrayerTimes daily, Prayer next, DateTime now) {
    final order = Prayer.all;
    final idx = order.indexOf(next);
    if (idx <= 0) {
      return DateTime(daily.date.year, daily.date.month, daily.date.day);
    }
    return daily.times[order[idx - 1]]!;
  }

  String _hijriString(DateTime d) {
    final h = HijriCalendar.fromDate(d);
    return '${h.hDay} ${h.longMonthName} ${h.hYear}';
  }
}
