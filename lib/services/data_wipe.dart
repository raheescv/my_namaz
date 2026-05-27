import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database.dart';
import '../data/prayer_dao.dart';
import '../data/user_dao.dart';
import 'notification_service.dart';

class DataWipe {
  DataWipe._();

  /// Erase every trace of the user from this device:
  /// - all prayer records
  /// - user profile
  /// - avatar files in the app documents directory
  /// - all SharedPreferences (theme, locale, login flag, etc.)
  /// - any scheduled notifications
  ///
  /// Also sets a flag so the auto-seeder in main.dart does not refill
  /// the database with sample data after the wipe.
  static Future<void> everything() async {
    // 1. Database
    try {
      await PrayerDao().deleteAll();
      await UserDao().deleteAll();
      await AppDatabase.instance.close();
    } catch (e) {
      debugPrint('[wipe] db: $e');
    }

    // 2. Avatar files
    try {
      final dir = await getApplicationDocumentsDirectory();
      final entities = dir.listSync();
      for (final e in entities) {
        final name = e.path.split('/').last;
        if (name.startsWith('avatar_') && e is File) {
          try {
            await e.delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[wipe] avatars: $e');
    }

    // 3. Notifications
    try {
      await NotificationService.cancelAll();
    } catch (e) {
      debugPrint('[wipe] notifications: $e');
    }

    // 4. SharedPreferences — wipe everything, then mark that the user
    // explicitly cleared so we don't re-seed sample data on next launch.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setBool('wipedByUser', true);
    } catch (e) {
      debugPrint('[wipe] prefs: $e');
    }
  }

  /// Returns true if the user has previously chosen "Delete all my data".
  /// Used to suppress the sample-data seeder.
  static Future<bool> wasWiped() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('wipedByUser') ?? false;
    } catch (_) {
      return false;
    }
  }
}
