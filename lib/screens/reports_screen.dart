import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/prayer_enum.dart';
import '../models/prayer_record.dart';
import '../providers/prayer_provider.dart';
import '../services/stats_service.dart';
import '../theme/colors.dart';
import '../utils/date_utils.dart';

enum _Period { week, month, year, all }

extension _PeriodLabel on _Period {
  String get label {
    switch (this) {
      case _Period.week:
        return 'Week';
      case _Period.month:
        return 'Month';
      case _Period.year:
        return 'Year';
      case _Period.all:
        return 'All';
    }
  }
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  _Period _period = _Period.month;

  ({DateTime start, DateTime end}) _range() {
    final now = DateTime.now();
    switch (_period) {
      case _Period.week:
        return (
          start: DateX.dayOnly(now.subtract(const Duration(days: 6))),
          end: DateX.dayOnly(now),
        );
      case _Period.month:
        return (
          start: DateX.startOfMonth(now),
          end: DateX.dayOnly(now),
        );
      case _Period.year:
        return (
          start: DateX.startOfYear(now),
          end: DateX.dayOnly(now),
        );
      case _Period.all:
        return (start: DateTime(2020, 1, 1), end: DateX.dayOnly(now));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = _range();
    final recordsAsync = ref.watch(rangeRecordsProvider(r));
    final allAsync = ref.watch(allRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: 'Table report',
            onPressed: () => context.push('/table-report'),
          ),
        ],
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (records) {
          final streak = allAsync.maybeWhen(
            data: (rs) => StatsService.perfectStreaks(rs),
            orElse: () => const StreakResult(0, 0),
          );
          final last30Records = allAsync.maybeWhen(
            data: (rs) {
              final cut =
                  DateTime.now().subtract(const Duration(days: 30));
              return rs.where((r) => r.date.isAfter(cut)).toList();
            },
            orElse: () => <PrayerRecord>[],
          );
          final consistency =
              StatsService.consistencyScore(last30Records);
          final completed = StatsService.totalCompleted(records);
          final missed = StatsService.totalMissed(records);
          final total = completed + missed;
          final pct =
              total == 0 ? 0 : ((completed / total) * 100).round();
          final perPrayer = StatsService.perPrayerRate(records);
          final dow = StatsService.dayOfWeekRate(records);
          final missedList = StatsService.missedList(records);

          if (records.isEmpty) return _emptyState(theme);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                children: [
                  _periodSelector(theme),
                  const SizedBox(height: 18),
                  _heroCard(theme, pct, completed, missed),
                  const SizedBox(height: 16),
                  _quickStats(theme, streak, consistency, records.length),
                  const SizedBox(height: 22),
                  _sectionTitle(theme, 'Per-prayer completion'),
                  const SizedBox(height: 10),
                  _card(theme, _perPrayerSection(theme, perPrayer)),
                  const SizedBox(height: 22),
                  _sectionTitle(theme, 'Daily trend'),
                  const SizedBox(height: 10),
                  _card(theme,
                      SizedBox(height: 200, child: _trendChart(records, theme))),
                  const SizedBox(height: 22),
                  _sectionTitle(theme, 'Day of week'),
                  const SizedBox(height: 10),
                  _card(theme,
                      SizedBox(height: 200, child: _dowChart(dow, theme))),
                  const SizedBox(height: 22),
                  _sectionTitle(theme, 'Where you miss most'),
                  const SizedBox(height: 10),
                  _card(theme,
                      SizedBox(height: 200, child: _missedPie(records, theme))),
                  const SizedBox(height: 22),
                  _sectionTitle(theme, 'Last 6 months at a glance'),
                  const SizedBox(height: 10),
                  _card(theme, _heatmap(records, theme)),
                  const SizedBox(height: 22),
                  if (missedList.isNotEmpty) ...[
                    _sectionTitle(theme, 'Recent missed'),
                    const SizedBox(height: 10),
                    _card(theme, _missedListView(theme, missedList)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────── components ─────────────────────────

  Widget _periodSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final p in _Period.values)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _period = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: p == _period
                        ? AppColors.primaryGreen
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      p.label,
                      style: TextStyle(
                        color: p == _period
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: p == _period
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _heroCard(ThemeData theme, int pct, int completed, int missed) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.18),
            AppColors.deepTeal.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: CircularProgressIndicator(
                    value: pct / 100.0,
                    strokeWidth: 9,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.4),
                    valueColor: const AlwaysStoppedAnimation(
                        AppColors.primaryGreen),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$pct%',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          letterSpacing: -0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pct >= 80
                      ? 'Mashallah'
                      : pct >= 50
                          ? 'Keep going'
                          : "Let's improve",
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_periodSubtitle()} • $completed prayed, $missed missed',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _periodSubtitle() {
    switch (_period) {
      case _Period.week:
        return 'Last 7 days';
      case _Period.month:
        return 'This month';
      case _Period.year:
        return 'This year';
      case _Period.all:
        return 'All time';
    }
  }

  Widget _quickStats(ThemeData theme, StreakResult streak,
      int consistency, int daysLogged) {
    final items = [
      (
        icon: Icons.local_fire_department_outlined,
        color: AppColors.accentGold,
        label: 'Current streak',
        value: '${streak.current}d',
      ),
      (
        icon: Icons.emoji_events_outlined,
        color: AppColors.sectionCoral,
        label: 'Longest streak',
        value: '${streak.longest}d',
      ),
      (
        icon: Icons.show_chart,
        color: AppColors.sectionBlue,
        label: 'Consistency 30d',
        value: '$consistency%',
      ),
      (
        icon: Icons.event_note_outlined,
        color: AppColors.sectionPurple,
        label: 'Days logged',
        value: '$daysLogged',
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 76,
      ),
      itemBuilder: (_, i) {
        final it = items[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: it.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(it.icon, color: it.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      it.value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      it.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(ThemeData theme, String t) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          t,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      );

  Widget _card(ThemeData theme, Widget child) => Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        child: child,
      );

  // ─────────────── per-prayer ───────────────

  Widget _perPrayerSection(ThemeData theme, Map<Prayer, double> map) {
    final best = map.entries.fold<MapEntry<Prayer, double>?>(
        null,
        (a, b) =>
            a == null ? b : (b.value > a.value ? b : a));
    final worst = map.entries.fold<MapEntry<Prayer, double>?>(
        null,
        (a, b) =>
            a == null ? b : (b.value < a.value ? b : a));
    return Column(
      children: [
        for (final p in Prayer.all)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(p.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: map[p],
                      minHeight: 10,
                      backgroundColor:
                          theme.colorScheme.surface,
                      valueColor: AlwaysStoppedAnimation(
                        p == best?.key
                            ? AppColors.primaryGreen
                            : p == worst?.key
                                ? AppColors.statusMissed
                                    .withValues(alpha: 0.7)
                                : AppColors.primaryGreen
                                    .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${((map[p] ?? 0) * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        if (worst != null && worst.value < 0.9) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.statusMissed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppColors.statusMissed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Try to be more consistent with ${worst.key.name} — your lowest at ${(worst.value * 100).round()}%.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────── trend chart ───────────────

  Widget _trendChart(List<PrayerRecord> records, ThemeData theme) {
    if (records.isEmpty) {
      return const Center(child: Text('No data'));
    }
    final sorted = [...records]..sort((a, b) => a.date.compareTo(b.date));
    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), sorted[i].completedCount.toDouble()));
    }
    return LineChart(LineChartData(
      minY: 0,
      maxY: 5,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (_) => FlLine(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          strokeWidth: 0.6,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 24,
            getTitlesWidget: (v, _) => Text('${v.toInt()}',
                style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (sorted.length / 5).ceilToDouble().clamp(1, 30),
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= sorted.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(DateFormat('d/M').format(sorted[i].date),
                    style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant)),
              );
            },
          ),
        ),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.32,
          color: AppColors.primaryGreen,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGreen.withValues(alpha: 0.25),
                AppColors.primaryGreen.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    ));
  }

  // ─────────────── day-of-week chart ───────────────

  Widget _dowChart(Map<int, double> dow, ThemeData theme) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return BarChart(BarChartData(
      maxY: 1,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: 0.25,
            getTitlesWidget: (v, _) => Text(
                '${(v * 100).round()}%',
                style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                labels[v.toInt()],
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barGroups: [
        for (var w = 1; w <= 7; w++)
          BarChartGroupData(x: w - 1, barRods: [
            BarChartRodData(
              toY: dow[w] ?? 0,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGreen.withValues(alpha: 0.85),
                  AppColors.primaryGreen.withValues(alpha: 0.55),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              width: 22,
              borderRadius: BorderRadius.circular(6),
            ),
          ]),
      ],
    ));
  }

  // ─────────────── missed pie ───────────────

  Widget _missedPie(List<PrayerRecord> records, ThemeData theme) {
    final counts = {for (final p in Prayer.all) p: 0};
    for (final r in records) {
      for (final p in Prayer.all) {
        if (!r.isCompleted(p)) counts[p] = counts[p]! + 1;
      }
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.celebration,
              color: AppColors.primaryGreen, size: 32),
          const SizedBox(width: 12),
          Text(
            'Mashallah — no missed prayers!',
            style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w700),
          ),
        ],
      );
    }
    const palette = [
      Color(0xFFD64545),
      Color(0xFFE0A82E),
      Color(0xFF6B5B95),
      Color(0xFF2E86AB),
      Color(0xFF8B5A3C),
    ];
    return Row(
      children: [
        Expanded(
          child: PieChart(PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 38,
            sections: [
              for (int i = 0; i < Prayer.all.length; i++)
                if (counts[Prayer.all[i]]! > 0)
                  PieChartSectionData(
                    value: counts[Prayer.all[i]]!.toDouble(),
                    title:
                        '${((counts[Prayer.all[i]]! / total) * 100).round()}%',
                    radius: 56,
                    color: palette[i % palette.length],
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11),
                  ),
            ],
          )),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < Prayer.all.length; i++)
                if (counts[Prayer.all[i]]! > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: palette[i % palette.length],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Prayer.all[i].name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          '${counts[Prayer.all[i]]}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────── heatmap ───────────────

  Widget _heatmap(List<PrayerRecord> records, ThemeData theme) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 5, 1);
    final days = DateX.rangeInclusive(start, now);
    final byDate = {for (final r in records) DateX.ymd(r.date): r};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 3,
          runSpacing: 3,
          children: [
            for (final d in days)
              Tooltip(
                message:
                    '${DateX.pretty(d)}: ${byDate[DateX.ymd(d)]?.completedCount ?? 0}/5',
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _heatColor(byDate[DateX.ymd(d)]?.completedCount ?? 0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('Less',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(width: 6),
            for (var i = 0; i <= 5; i++) ...[
              Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _heatColor(i),
                    borderRadius: BorderRadius.circular(3),
                  )),
              const SizedBox(width: 3),
            ],
            const SizedBox(width: 3),
            Text('More',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }

  Color _heatColor(int count) {
    switch (count) {
      case 5:
        return AppColors.primaryGreen;
      case 4:
        return AppColors.primaryGreen.withValues(alpha: 0.75);
      case 3:
        return AppColors.primaryGreen.withValues(alpha: 0.55);
      case 2:
        return AppColors.primaryGreen.withValues(alpha: 0.35);
      case 1:
        return AppColors.primaryGreen.withValues(alpha: 0.2);
      default:
        return AppColors.statusMissed.withValues(alpha: 0.12);
    }
  }

  // ─────────────── missed list ───────────────

  Widget _missedListView(
      ThemeData theme, List<(DateTime, Prayer)> missedList) {
    final preview = missedList.take(8).toList();
    return Column(
      children: [
        for (final (d, p) in preview)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        AppColors.statusMissed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close,
                      color: AppColors.statusMissed, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(p.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                ),
                Text(
                  DateFormat('d MMM').format(d),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        if (missedList.length > preview.length)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+${missedList.length - preview.length} more',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Widget _emptyState(ThemeData theme) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.insights_outlined,
                    color: AppColors.primaryGreen, size: 48),
              ),
              const SizedBox(height: 18),
              Text(
                'No data yet',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Start marking prayers as completed on the Today tab to see your stats here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
}
