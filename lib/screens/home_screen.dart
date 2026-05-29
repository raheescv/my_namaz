import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';

import '../models/prayer_enum.dart';
import '../models/prayer_record.dart';
import '../models/user_profile.dart';
import '../providers/prayer_provider.dart';
import '../providers/prayer_times_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../services/stats_service.dart';
import '../theme/colors.dart';
import '../utils/date_utils.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/prayer_card.dart';
import '../widgets/prayer_times_card.dart';

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
    final profile = ref.watch(profileProvider);
    final allAsync = ref.watch(allRecordsProvider);
    final daily = ref.watch(dailyPrayerTimesProvider);
    final now = DateTime.now();
    final nextPrayer = daily?.next(now)?.prayer;

    final streak = allAsync.maybeWhen(
      data: (rs) => StatsService.perfectStreaks(rs),
      orElse: () => const StreakResult(0, 0),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: recordAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (record) {
            _syncNotes(record);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              children: [
                _header(theme, profile, streak.current),
                const SizedBox(height: 18),
                _dateBar(theme, date, settings.hijriEnabled),
                const SizedBox(height: 14),
                _summaryCard(theme, record, streak),
                const SizedBox(height: 14),
                const PrayerTimesCard(),
                const SizedBox(height: 22),
                _sectionTitle(theme, "Today's prayers"),
                const SizedBox(height: 8),
                for (final p in Prayer.all)
                  PrayerCard(
                    prayer: p,
                    completed: record.isCompleted(p),
                    time: daily?.times[p],
                    isNext: nextPrayer == p,
                    onTap: () =>
                        ref.read(prayerControllerProvider).toggle(p),
                  ),
                const SizedBox(height: 22),
                _sectionTitle(theme, 'Notes'),
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
              ],
            ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String t) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(t,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface)),
      );

  Widget _header(
      ThemeData theme, UserProfile? profile, int streakDays) {
    final name = profile?.name ?? '';
    final avatarPath = profile?.avatarPath;
    return Row(
      children: [
        InitialsAvatar(
          name: name.isEmpty ? '?' : name,
          avatarPath: avatarPath,
          radius: 24,
          onTap: () => context.push('/profile'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assalamu Alaikum',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.3,
                  )),
              const SizedBox(height: 2),
              Text(name.isEmpty ? 'Friend' : name,
                  style: theme.textTheme.titleLarge),
            ],
          ),
        ),
        if (streakDays > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC468), Color(0xFFE07856)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('$streakDays',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dateBar(ThemeData theme, DateTime date, bool hijriOn) {
    final isToday = DateX.isToday(date);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant),
              onPressed: () => ref.read(selectedDateProvider.notifier).state =
                  DateX.dayOnly(date.subtract(const Duration(days: 1))),
            ),
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Text(DateX.pretty(date),
                          style: theme.textTheme.titleMedium),
                      if (hijriOn)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(_hijriString(date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.accentGold,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant),
              onPressed: isToday
                  ? null
                  : () => ref.read(selectedDateProvider.notifier).state =
                      DateX.dayOnly(date.add(const Duration(days: 1))),
            ),
            if (!isToday)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.tonal(
                  onPressed: () => ref
                      .read(selectedDateProvider.notifier)
                      .state = DateX.dayOnly(DateTime.now()),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Today'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _hijriString(DateTime d) {
    final h = HijriCalendar.fromDate(d);
    return '${h.hDay} ${h.longMonthName} ${h.hYear} AH';
  }

  Widget _summaryCard(
      ThemeData theme, PrayerRecord record, StreakResult streak) {
    final done = record.completedCount;
    final progress = done / 5.0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.12),
            AppColors.deepTeal.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation(
                        AppColors.primaryGreen),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text('$done/5',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.isPerfect
                      ? '✨ Alhamdulillah'
                      : (done == 0
                          ? "Let's begin"
                          : 'Keep going'),
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  done == 5
                      ? 'All five prayers completed today.'
                      : '${5 - done} prayer${5 - done == 1 ? '' : 's'} left for today',
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
}
