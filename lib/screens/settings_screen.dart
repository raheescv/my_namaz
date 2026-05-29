import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/prayer_provider.dart';
import '../providers/prayer_times_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../services/data_wipe.dart';
import '../services/notification_service.dart';
import '../services/prayer_times_service.dart';
import '../theme/colors.dart';
import '../utils/date_utils.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _languages = [
    Locale('en'),
    Locale('ar'),
    Locale('ur'),
  ];

  String _langLabel(Locale l) {
    switch (l.languageCode) {
      case 'ar':
        return 'العربية';
      case 'ur':
        return 'اردو';
      default:
        return 'English';
    }
  }

  String _themeLabel(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final profile = ref.watch(profileProvider);
    final calc = ref.watch(calcSettingsProvider);
    final loc = ref.watch(locationProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // Profile hero card
          _ProfileHero(profile: profile),
          const SizedBox(height: 22),

          _sectionLabel(theme, 'Appearance'),
          SettingsGroup(children: [
            SettingsTile(
              icon: Icons.brightness_6_outlined,
              iconColor: AppColors.sectionBlue,
              title: 'Theme',
              subtitle: _themeLabel(settings.themeMode),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => _pickTheme(context, ref, settings.themeMode),
            ),
            SettingsTile(
              icon: Icons.language,
              iconColor: AppColors.sectionPurple,
              title: 'Language',
              subtitle: _langLabel(settings.locale),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => _pickLanguage(context, ref, settings.locale),
            ),
            SettingsTile(
              icon: Icons.calendar_today_outlined,
              iconColor: AppColors.accentGold,
              title: 'Show Hijri date',
              trailing: Switch(
                value: settings.hijriEnabled,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setHijri(v),
              ),
            ),
          ]),

          const SizedBox(height: 22),
          _sectionLabel(theme, 'Prayer times'),
          SettingsGroup(children: [
            ExpandableSettingsTile(
              icon: Icons.my_location_outlined,
              iconColor: AppColors.primaryGreen,
              title: 'Location',
              subtitle: loc?.city ??
                  (loc == null
                      ? 'Not set'
                      : '${loc.latitude.toStringAsFixed(2)}, ${loc.longitude.toStringAsFixed(2)}'),
              initiallyExpanded: loc != null,
              children: [
                SubSettingsRow(
                  title: 'Automatic',
                  trailing: Switch(
                    value: loc?.mode == LocationMode.automatic,
                    onChanged: (v) => ref
                        .read(locationProvider.notifier)
                        .setAutomatic(v),
                  ),
                ),
                SubSettingsRow(
                  title: 'City',
                  value: loc?.city ?? '—',
                  onTap: loc?.mode == LocationMode.automatic
                      ? () => ref
                          .read(locationProvider.notifier)
                          .refresh()
                      : () => context.push('/location-search'),
                ),
                SubSettingsRow(
                  title: 'Time zone',
                  value: _timeZoneLabel(),
                ),
                SubSettingsRow(
                  title: 'Coordinates',
                  value: loc == null
                      ? '—'
                      : '${loc.latitude.toStringAsFixed(2)}°, ${loc.longitude.toStringAsFixed(2)}°',
                ),
              ],
            ),
            SettingsTile(
              icon: Icons.calculate_outlined,
              iconColor: AppColors.sectionBlue,
              title: 'Calculation method',
              subtitle: PrayerTimesService.methodLabel(calc.method),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => _pickMethod(context, ref, calc.method),
            ),
            SettingsTile(
              icon: Icons.book_outlined,
              iconColor: AppColors.sectionBrown,
              title: 'Madhab',
              subtitle: PrayerTimesService.madhabLabel(calc.madhab) +
                  (calc.madhab == adhan.Madhab.hanafi
                      ? ' • Later Asr'
                      : ' • Standard Asr'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => _pickMadhab(context, ref, calc.madhab),
            ),
          ]),

          const SizedBox(height: 22),
          _sectionLabel(theme, 'Reminders'),
          SettingsGroup(children: [
            SettingsTile(
              icon: Icons.notifications_outlined,
              iconColor: AppColors.sectionCoral,
              title: 'Prayer reminders',
              subtitle: 'Daily at approximate prayer times',
              trailing: Switch(
                value: settings.remindersEnabled,
                onChanged: (v) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setReminders(v);
                  if (v) {
                    await NotificationService.requestPermissions();
                    await NotificationService.scheduleDailyReminders();
                  } else {
                    await NotificationService.cancelAll();
                  }
                },
              ),
            ),
          ]),

          const SizedBox(height: 22),
          _sectionLabel(theme, 'Account'),
          SettingsGroup(children: [
            SettingsTile(
              icon: Icons.logout_outlined,
              iconColor: AppColors.statusMissed,
              title: 'Logout',
              subtitle: 'Your prayer records will be kept',
              onTap: () => _confirmLogout(context, ref),
            ),
            SettingsTile(
              icon: Icons.delete_forever_outlined,
              iconColor: AppColors.statusMissed,
              title: 'Delete this account',
              subtitle: 'This cannot be undone',
              onTap: () => _confirmWipe(context, ref),
            ),
          ]),

          const SizedBox(height: 28),
          Center(
            child: Text(
              'All your data is stored only on this device.\nNothing is sent to any server.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  /// IANA-ish time zone label using the device's current offset.
  /// Falls back to "UTC±HH:MM" when no name is reported.
  String _timeZoneLabel() {
    final now = DateTime.now();
    final name = now.timeZoneName; // e.g. "IST" or "India Standard Time"
    final off = now.timeZoneOffset;
    final sign = off.isNegative ? '-' : '+';
    final h = off.inHours.abs();
    final m = off.inMinutes.abs() % 60;
    final pad = m.toString().padLeft(2, '0');
    final hp = h.toString().padLeft(2, '0');
    if (name.trim().isEmpty || name == 'Local') {
      return 'UTC$sign$hp:$pad';
    }
    return '$name (UTC$sign$hp:$pad)';
  }

  Widget _sectionLabel(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
        child: Text(
          text.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
            letterSpacing: 1.4,
          ),
        ),
      );

  // ──── Pickers ────────────────────────────────────────────────────────────

  Future<void> _pickTheme(
      BuildContext context, WidgetRef ref, ThemeMode current) async {
    final picked = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Theme',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final m in ThemeMode.values)
              ListTile(
                leading: Icon(_themeIcon(m)),
                title: Text(_themeLabel(m)),
                trailing: current == m
                    ? const Icon(Icons.check, color: AppColors.primaryGreen)
                    : null,
                onTap: () => Navigator.pop(context, m),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).setThemeMode(picked);
    }
  }

  IconData _themeIcon(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  Future<void> _pickLanguage(
      BuildContext context, WidgetRef ref, Locale current) async {
    final picked = await showModalBottomSheet<Locale>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Language',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final l in _languages)
              ListTile(
                title: Text(_langLabel(l)),
                trailing: current.languageCode == l.languageCode
                    ? const Icon(Icons.check, color: AppColors.primaryGreen)
                    : null,
                onTap: () => Navigator.pop(context, l),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).setLocale(picked);
    }
  }

  Future<void> _pickMethod(BuildContext context, WidgetRef ref,
      adhan.CalculationMethod current) async {
    final picked = await showModalBottomSheet<adhan.CalculationMethod>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Calculation method',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final m in adhan.CalculationMethod.values)
              if (m != adhan.CalculationMethod.other)
                ListTile(
                  title: Text(PrayerTimesService.methodLabel(m)),
                  trailing: current == m
                      ? const Icon(Icons.check,
                          color: AppColors.primaryGreen)
                      : null,
                  onTap: () => Navigator.pop(context, m),
                ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(calcSettingsProvider.notifier).setMethod(picked);
    }
  }

  Future<void> _pickMadhab(BuildContext context, WidgetRef ref,
      adhan.Madhab current) async {
    final picked = await showModalBottomSheet<adhan.Madhab>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Madhab',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            ListTile(
              title: const Text('Shafi / Maliki / Hanbali'),
              subtitle: const Text('Standard Asr'),
              trailing: current == adhan.Madhab.shafi
                  ? const Icon(Icons.check, color: AppColors.primaryGreen)
                  : null,
              onTap: () => Navigator.pop(context, adhan.Madhab.shafi),
            ),
            ListTile(
              title: const Text('Hanafi'),
              subtitle: const Text('Later Asr'),
              trailing: current == adhan.Madhab.hanafi
                  ? const Icon(Icons.check, color: AppColors.primaryGreen)
                  : null,
              onTap: () => Navigator.pop(context, adhan.Madhab.hanafi),
            ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(calcSettingsProvider.notifier).setMadhab(picked);
    }
  }

  // ──── Logout / wipe ──────────────────────────────────────────────────────

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final authNotifier = container.read(authProvider.notifier);

    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
            'This clears your login but keeps your prayer data. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Logout')),
        ],
      ),
    );
    if (ok == true) {
      await authNotifier.logout();
    }
  }

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final dateNotifier = container.read(selectedDateProvider.notifier);
    final authNotifier = container.read(authProvider.notifier);

    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete this account?'),
        content: Text(
            'This permanently deletes the profile for ${user.fullPhone} and every prayer record under it. Other accounts on this device are not affected. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Delete account')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      dateNotifier.state = DateX.dayOnly(DateTime.now());
      container.invalidate(allRecordsProvider);
      container.invalidate(selectedRecordProvider);
      await DataWipe.currentUser(user);
      await authNotifier.logout();
    } catch (e) {
      try {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Wipe failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      } catch (_) {}
    }
  }
}

class _ProfileHero extends StatelessWidget {
  final dynamic profile;
  const _ProfileHero({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push('/profile'),
      child: Container(
        padding: const EdgeInsets.all(18),
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
            InitialsAvatar(
              name: profile?.name ?? '?',
              avatarPath: profile?.avatarPath,
              radius: 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile?.name ?? 'Profile',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    profile?.email ?? profile?.fullPhone ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.primaryGreen),
          ],
        ),
      ),
    );
  }
}
