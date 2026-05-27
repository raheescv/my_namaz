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
import '../widgets/stat_card.dart';

enum _Period { week, month, year, all }

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
              final cut = DateTime.now().subtract(const Duration(days: 30));
              return rs.where((r) => r.date.isAfter(cut)).toList();
            },
            orElse: () => <PrayerRecord>[],
          );
          final consistency =
              StatsService.consistencyScore(last30Records);
          final completed = StatsService.totalCompleted(records);
          final missed = StatsService.totalMissed(records);
          final perPrayer = StatsService.perPrayerRate(records);
          final dow = StatsService.dayOfWeekRate(records);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _segmented(),
              const SizedBox(height: 16),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                children: [
                  StatCard(
                    label: 'Completed',
                    value: '$completed',
                    icon: Icons.check_circle_outline,
                    accent: AppColors.statusComplete,
                  ),
                  StatCard(
                    label: 'Missed',
                    value: '$missed',
                    icon: Icons.cancel_outlined,
                    accent: AppColors.statusMissed,
                  ),
                  StatCard(
                    label: 'Current streak',
                    value: '${streak.current}d',
                    icon: Icons.local_fire_department_outlined,
                    accent: AppColors.accentGold,
                  ),
                  StatCard(
                    label: 'Longest streak',
                    value: '${streak.longest}d',
                    icon: Icons.emoji_events_outlined,
                    accent: AppColors.accentGold,
                  ),
                  StatCard(
                    label: 'Consistency (30d)',
                    value: '$consistency%',
                    icon: Icons.show_chart,
                  ),
                  StatCard(
                    label: 'Days logged',
                    value: '${records.length}',
                    icon: Icons.event_note_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _sectionTitle(theme, 'Per-prayer completion'),
              _perPrayerBar(perPrayer, theme),
              const SizedBox(height: 24),
              _sectionTitle(theme, 'Daily completion trend'),
              SizedBox(height: 200, child: _trendChart(records, theme)),
              const SizedBox(height: 24),
              _sectionTitle(theme, 'Day of week'),
              SizedBox(height: 200, child: _dowChart(dow, theme)),
              const SizedBox(height: 24),
              _sectionTitle(theme, 'Distribution of missed prayers'),
              SizedBox(height: 220, child: _missedPie(records, theme)),
              const SizedBox(height: 24),
              _sectionTitle(theme, 'Year heatmap'),
              _heatmap(records, theme),
            ],
          );
        },
      ),
    );
  }

  Widget _segmented() {
    return SegmentedButton<_Period>(
      segments: const [
        ButtonSegment(value: _Period.week, label: Text('Week')),
        ButtonSegment(value: _Period.month, label: Text('Month')),
        ButtonSegment(value: _Period.year, label: Text('Year')),
        ButtonSegment(value: _Period.all, label: Text('All')),
      ],
      selected: {_period},
      onSelectionChanged: (s) => setState(() => _period = s.first),
    );
  }

  Widget _sectionTitle(ThemeData theme, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      );

  Widget _perPrayerBar(Map<Prayer, double> map, ThemeData theme) {
    return Column(
      children: [
        for (final p in Prayer.all)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 72, child: Text(p.name)),
                Expanded(
                  child: LinearProgressIndicator(
                    value: map[p],
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(6),
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation(
                        AppColors.primaryGreen),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                    width: 44,
                    child: Text('${((map[p] ?? 0) * 100).round()}%',
                        textAlign: TextAlign.right)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _trendChart(List<PrayerRecord> records, ThemeData theme) {
    if (records.isEmpty) {
      return const Center(child: Text('No data'));
    }
    final sorted = [...records]..sort((a, b) => a.date.compareTo(b.date));
    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(),
          sorted[i].completedCount.toDouble()));
    }
    return LineChart(LineChartData(
      minY: 0,
      maxY: 5,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(
            sideTitles:
                SideTitles(showTitles: true, interval: 1, reservedSize: 24)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (sorted.length / 5).ceilToDouble().clamp(1, 30),
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(DateFormat('d/M').format(sorted[i].date),
                    style: const TextStyle(fontSize: 10)),
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
          color: AppColors.primaryGreen,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryGreen.withValues(alpha: 0.15)),
        ),
      ],
    ));
  }

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
            reservedSize: 32,
            interval: 0.25,
            getTitlesWidget: (v, _) =>
                Text('${(v * 100).round()}%',
                    style: const TextStyle(fontSize: 10)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(labels[v.toInt()],
                  style: const TextStyle(fontSize: 12)),
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
              color: AppColors.primaryGreen,
              width: 18,
              borderRadius: BorderRadius.circular(4),
            ),
          ]),
      ],
    ));
  }

  Widget _missedPie(List<PrayerRecord> records, ThemeData theme) {
    final counts = {for (final p in Prayer.all) p: 0};
    for (final r in records) {
      for (final p in Prayer.all) {
        if (!r.isCompleted(p)) counts[p] = counts[p]! + 1;
      }
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return const Center(child: Text('No missed prayers — Mashallah!'));
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
            sectionsSpace: 2,
            centerSpaceRadius: 36,
            sections: [
              for (int i = 0; i < Prayer.all.length; i++)
                if (counts[Prayer.all[i]]! > 0)
                  PieChartSectionData(
                    value: counts[Prayer.all[i]]!.toDouble(),
                    title: '${counts[Prayer.all[i]]}',
                    radius: 60,
                    color: palette[i % palette.length],
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
            ],
          )),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < Prayer.all.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                          width: 10,
                          height: 10,
                          color: palette[i % palette.length]),
                      const SizedBox(width: 8),
                      Text(
                          '${Prayer.all[i].name}  ${counts[Prayer.all[i]]}'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heatmap(List<PrayerRecord> records, ThemeData theme) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 6, 1);
    final days = DateX.rangeInclusive(start, now);
    final byDate = {for (final r in records) DateX.ymd(r.date): r};
    return Wrap(
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
        return Colors.grey.withValues(alpha: 0.2);
    }
  }
}
