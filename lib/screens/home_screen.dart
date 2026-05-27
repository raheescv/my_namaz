import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';

import '../models/prayer_enum.dart';
import '../models/prayer_record.dart';
import '../models/user_profile.dart';
import '../providers/prayer_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../services/stats_service.dart';
import '../theme/colors.dart';
import '../utils/date_utils.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/prayer_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _notesCtrl = TextEditingController();
  String? _loadedForKey;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _syncNotes(PrayerRecord record) {
    final key = DateX.ymd(record.date);
    if (_loadedForKey != key) {
      _notesCtrl.text = record.notes ?? '';
      _loadedForKey = key;
    }
  }

  Future<void> _pickDate() async {
    final current = ref.read(selectedDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state = DateX.dayOnly(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final date = ref.watch(selectedDateProvider);
    final recordAsync = ref.watch(selectedRecordProvider);
    final profileAsync = ref.watch(profileProvider);
    final allAsync = ref.watch(allRecordsProvider);

    final streak = allAsync.maybeWhen(
      data: (rs) => StatsService.perfectStreaks(rs),
      orElse: () => const StreakResult(0, 0),
    );

    return Scaffold(
      body: SafeArea(
        child: recordAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (record) {
            _syncNotes(record);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _header(theme, profileAsync, streak.current),
                const SizedBox(height: 16),
                _dateBar(theme, date),
                const SizedBox(height: 8),
                _hijriLine(theme, date, settings.hijriEnabled),
                const SizedBox(height: 12),
                _summaryChip(theme, record),
                const SizedBox(height: 12),
                for (final p in Prayer.all)
                  PrayerCard(
                    prayer: p,
                    completed: record.isCompleted(p),
                    onTap: () =>
                        ref.read(prayerControllerProvider).toggle(p),
                  ),
                const SizedBox(height: 24),
                Text('Notes',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'How was your day?',
                  ),
                  onChanged: (v) => ref
                      .read(prayerControllerProvider)
                      .saveNotes(v.isEmpty ? null : v),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(
      ThemeData theme, AsyncValue<UserProfile?> profile, int streakDays) {
    final name = profile.maybeWhen(
        data: (p) => p?.name ?? '', orElse: () => '');
    final avatarPath =
        profile.maybeWhen(data: (p) => p?.avatarPath, orElse: () => null);
    return Row(
      children: [
        InitialsAvatar(
          name: name.isEmpty ? '?' : name,
          avatarPath: avatarPath,
          radius: 22,
          onTap: () => context.push('/profile'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assalamu Alaikum',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              Text(name.isEmpty ? 'Friend' : name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (streakDays > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text('$streakDays',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dateBar(ThemeData theme, DateTime date) {
    final isToday = DateX.isToday(date);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => ref.read(selectedDateProvider.notifier).state =
                  DateX.dayOnly(date.subtract(const Duration(days: 1))),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: Column(
                  children: [
                    Text(DateX.pretty(date),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: isToday
                  ? null
                  : () => ref.read(selectedDateProvider.notifier).state =
                      DateX.dayOnly(date.add(const Duration(days: 1))),
            ),
            if (!isToday)
              TextButton(
                onPressed: () => ref
                    .read(selectedDateProvider.notifier)
                    .state = DateX.dayOnly(DateTime.now()),
                child: const Text('Today'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hijriLine(ThemeData theme, DateTime date, bool enabled) {
    if (!enabled) return const SizedBox.shrink();
    final h = HijriCalendar.fromDate(date);
    return Center(
      child: Text(
        '${h.hDay} ${h.longMonthName} ${h.hYear} AH',
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _summaryChip(ThemeData theme, PrayerRecord record) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Text('${record.completedCount} of 5 completed',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          if (record.isPerfect)
            const Text('✨ Alhamdulillah',
                style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
