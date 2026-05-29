import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database.dart';
import '../data/prayer_dao.dart';
import '../data/user_dao.dart';
import '../models/user_profile.dart';
import 'notification_service.dart';

class DataWipe {
  DataWipe._();

  /// Erase one account: their prayer records, their profile row, their
  /// avatar file, scheduled notifications, and the "current user" pointer.
  /// Other users on this device remain intact.
  static Future<void> currentUser(UserProfile user) async {
    try {
      if (user.id != null) {
        await PrayerDao().deleteAllForUser(user.id!);
        await UserDao().deleteById(user.id!);
      }
    } catch (e) {
      debugPrint('[wipe.user] db: $e');
    }

    // Their avatar, if any
    try {
      final path = user.avatarPath;
      if (path != null) {
        final f = File(path);
        if (await f.exists()) await f.delete();
      }
    } catch (e) {
      debugPrint('[wipe.user] avatar: $e');
    }

    try {
      await NotificationService.cancelAll();
    } catch (e) {
      debugPrint('[wipe.user] notif: $e');
    }

    // Forget the current-user pointer.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUserId');
    } catch (e) {
      debugPrint('[wipe.user] prefs: $e');
    }
  }

  /// Nuclear option: erase every user on this device, every record,
  /// every preference, every avatar file. Useful for QA / testing only.
  static Future<void> everything() async {
    try {
      await PrayerDao().deleteAll();
      await UserDao().deleteAll();
      await AppDatabase.instance.close();
    } catch (e) {
      debugPrint('[wipe.all] db: $e');
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      for (final e in dir.listSync()) {
        final name = e.path.split('/').last;
        if (name.startsWith('avatar_') && e is File) {
          try {
            await e.delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[wipe.all] avatars: $e');
    }

    try {
      await NotificationService.cancelAll();
    } catch (e) {
      debugPrint('[wipe.all] notif: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('[wipe.all] prefs: $e');
    }
  }
}
