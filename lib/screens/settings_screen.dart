import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/prayer_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import '../services/data_wipe.dart';
import '../services/notification_service.dart';
import '../utils/date_utils.dart';
import '../widgets/initials_avatar.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Profile card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Card(
              child: ListTile(
                leading: profileAsync.when(
                  data: (p) => InitialsAvatar(
                    name: p?.name ?? '?',
                    avatarPath: p?.avatarPath,
                    radius: 24,
                  ),
                  loading: () => const CircleAvatar(radius: 24),
                  error: (_, __) => const CircleAvatar(radius: 24),
                ),
                title: Text(profileAsync.value?.name ?? 'Profile',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  profileAsync.value?.email ??
                      profileAsync.value?.fullPhone ??
                      '',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile'),
              ),
            ),
          ),

          _sectionLabel(theme, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox.shrink(),
              onChanged: (m) =>
                  ref.read(settingsProvider.notifier).setThemeMode(m!),
              items: const [
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(
                    value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(
                    value: ThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: DropdownButton<Locale>(
              value: _languages.firstWhere(
                  (l) => l.languageCode == settings.locale.languageCode,
                  orElse: () => const Locale('en')),
              underline: const SizedBox.shrink(),
              onChanged: (l) =>
                  ref.read(settingsProvider.notifier).setLocale(l!),
              items: [
                for (final l in _languages)
                  DropdownMenuItem(value: l, child: Text(_langLabel(l))),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_today_outlined),
            title: const Text('Show Hijri date'),
            value: settings.hijriEnabled,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setHijri(v),
          ),

          _sectionLabel(theme, 'Reminders'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Prayer reminders'),
            subtitle: const Text('Daily at approximate prayer times'),
            value: settings.remindersEnabled,
            onChanged: (v) async {
              await ref.read(settingsProvider.notifier).setReminders(v);
              if (v) {
                await NotificationService.requestPermissions();
                await NotificationService.scheduleDailyReminders();
              } else {
                await NotificationService.cancelAll();
              }
            },
          ),

          _sectionLabel(theme, 'Data'),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Export backup (JSON)'),
            onTap: () async {
              await BackupService.exportJson();
            },
          ),

          _sectionLabel(theme, 'Account'),
          ListTile(
            leading:
                const Icon(Icons.logout_outlined, color: Colors.red),
            title: const Text('Logout',
                style: TextStyle(color: Colors.red)),
            subtitle: const Text('Your prayer records will be kept'),
            onTap: () => _confirmLogout(context, ref),
          ),
          ListTile(
            leading:
                const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: const Text('Delete all my data',
                style: TextStyle(color: Colors.red)),
            subtitle: const Text('This cannot be undone'),
            onTap: () => _confirmWipe(context, ref),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'All your data is stored only on this device.\nNothing is sent to any server.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          text.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
            letterSpacing: 1.2,
          ),
        ),
      );

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
            'This clears your login but keeps your prayer data. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authProvider.notifier).setLoggedIn(false);
    }
  }

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
            'This permanently deletes your profile and every prayer record. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete everything')),
        ],
      ),
    );
    if (ok != true) return;
    await DataWipe.everything();

    // Reset all in-memory state so the UI reflects a fresh app.
    ref.invalidate(profileProvider);
    ref.invalidate(allRecordsProvider);
    ref.invalidate(selectedRecordProvider);
    ref.read(selectedDateProvider.notifier).state =
        DateX.dayOnly(DateTime.now());

    // Also tear down the StateNotifier-based controllers so their
    // cached state (theme, locale, login) reloads from the now-empty prefs.
    ref.invalidate(settingsProvider);
    ref.invalidate(authProvider);

    // The authProvider listener in the router will redirect to /login
    // once its reloaded state shows isLoggedIn=false.
  }
}
