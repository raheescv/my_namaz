import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/prayer_enum.dart';
import '../models/prayer_record.dart';
import '../providers/prayer_provider.dart';
import '../providers/profile_provider.dart';
import '../services/export_service.dart';
import '../theme/colors.dart';
import '../utils/date_utils.dart';

class TableReportScreen extends ConsumerStatefulWidget {
  const TableReportScreen({super.key});
  @override
  ConsumerState<TableReportScreen> createState() =>
      _TableReportScreenState();
}

class _TableReportScreenState extends ConsumerState<TableReportScreen> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateX.startOfMonth(now);
    _to = DateX.dayOnly(now);
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked != null) {
      setState(() {
        _from = DateX.dayOnly(picked.start);
        _to = DateX.dayOnly(picked.end);
      });
    }
  }

  Color _rowColor(PrayerRecord? r) {
    if (r == null) return Colors.transparent;
    if (r.completedCount == 5) {
      return AppColors.statusComplete.withValues(alpha: 0.08);
    }
    if (r.completedCount >= 3) {
      return AppColors.statusPartial.withValues(alpha: 0.10);
    }
    if (r.completedCount > 0) {
      return AppColors.statusMissed.withValues(alpha: 0.07);
    }
    return AppColors.statusMissed.withValues(alpha: 0.15);
  }

  static const _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  String _fmtDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${d.day}-${d.month}-${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recordsAsync =
        ref.watch(rangeRecordsProvider((start: _from, end: _to)));
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Report'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_outlined),
            onSelected: (v) async {
              final records = recordsAsync.value ?? [];
              if (v == 'csv') {
                await ExportService.exportCsv(records, profile,
                    from: _from, to: _to);
              } else {
                await ExportService.exportPdf(records, profile,
                    from: _from, to: _to);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
              PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.date_range),
                title: Text(
                    '${_fmtDate(_from)}  —  ${_fmtDate(_to)}'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _pickRange,
              ),
            ),
          ),
          Expanded(
            child: recordsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (records) {
                final byDate = {
                  for (final r in records) DateX.ymd(r.date): r,
                };
                final allDays = DateX.rangeInclusive(_from, _to);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width),
                      child: DataTable(
                        columnSpacing: 18,
                        headingRowColor: WidgetStateProperty.all(
                            theme.colorScheme.surfaceContainerHighest),
                        headingTextStyle: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Fajr'), numeric: false),
                          DataColumn(label: Text('Dhuhr'), numeric: false),
                          DataColumn(label: Text('Asr'), numeric: false),
                          DataColumn(
                              label: Text('Maghrib'), numeric: false),
                          DataColumn(label: Text('Isha'), numeric: false),
                        ],
                        rows: [
                          for (final day in allDays)
                            _row(theme, day, byDate[DateX.ymd(day)]),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DataRow _row(ThemeData theme, DateTime day, PrayerRecord? r) {
    return DataRow(
      color: WidgetStateProperty.all(_rowColor(r)),
      onSelectChanged: (_) {
        ref.read(selectedDateProvider.notifier).state = DateX.dayOnly(day);
        context.go('/home');
      },
      cells: [
        DataCell(Text(
          _fmtDate(day),
          style: const TextStyle(fontWeight: FontWeight.w500),
        )),
        for (final p in Prayer.all) _cell(r, p),
      ],
    );
  }

  DataCell _cell(PrayerRecord? r, Prayer p) {
    if (r == null) return const DataCell(SizedBox.shrink());
    final ok = r.isCompleted(p);
    return DataCell(
      Icon(
        ok ? Icons.check_circle : Icons.cancel,
        color: ok ? AppColors.statusComplete : AppColors.statusMissed,
        size: 20,
      ),
    );
  }
}
