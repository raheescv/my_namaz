import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/prayer_record.dart';
import '../providers/prayer_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/colors.dart';
import '../utils/date_utils.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();

  Color? _dotColor(PrayerRecord? r) {
    if (r == null) return null;
    if (r.completedCount == 5) return AppColors.statusComplete;
    if (r.completedCount == 0) return AppColors.statusMissed;
    return AppColors.statusPartial;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hijriOn = ref.watch(settingsProvider).hijriEnabled;
    final allAsync = ref.watch(allRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: allAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (records) {
          final byDate = {for (final r in records) DateX.ymd(r.date): r};
          return ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar(
                    firstDay: DateTime(2020, 1, 1),
                    lastDay:
                        DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focused,
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                    },
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    onPageChanged: (d) => _focused = d,
                    onDaySelected: (selected, focused) {
                      ref.read(selectedDateProvider.notifier).state =
                          DateX.dayOnly(selected);
                      context.go('/home');
                    },
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, _) =>
                          _dayCell(day, byDate, hijriOn, theme),
                      todayBuilder: (context, day, _) =>
                          _dayCell(day, byDate, hijriOn, theme, isToday: true),
                      outsideBuilder: (context, day, _) =>
                          _dayCell(day, byDate, hijriOn, theme, outside: true),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _legend(theme),
            ],
          );
        },
      ),
    );
  }

  Widget _dayCell(
    DateTime day,
    Map<String, PrayerRecord> byDate,
    bool hijriOn,
    ThemeData theme, {
    bool isToday = false,
    bool outside = false,
  }) {
    final record = byDate[DateX.ymd(day)];
    final color = _dotColor(record);
    final textColor = outside
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
        : theme.colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isToday
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${day.day}',
              style: TextStyle(
                  color: textColor,
                  fontWeight:
                      isToday ? FontWeight.w700 : FontWeight.w500)),
          if (hijriOn)
            Text(
              '${HijriCalendar.fromDate(day).hDay}',
              style: TextStyle(
                  fontSize: 9,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.7)),
            ),
          const SizedBox(height: 2),
          if (color != null)
            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _legend(ThemeData theme) {
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          item(AppColors.statusComplete, 'All 5 prayed'),
          item(AppColors.statusPartial, 'Some prayed'),
          item(AppColors.statusMissed, 'None prayed'),
        ],
      ),
    );
  }
}
