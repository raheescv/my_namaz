import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/prayer_dao.dart';
import '../data/user_dao.dart';
import '../models/prayer_record.dart';
import '../models/user_profile.dart';
import '../utils/date_utils.dart';

class BackupService {
  BackupService._();

  static Future<void> exportJson() async {
    final user = await UserDao().get();
    final records = await PrayerDao().getAll();
    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': user?.toMap(),
      'records': records.map((r) => r.toMap()).toList(),
    };
    final dir = await getTemporaryDirectory();
    final fname =
        'namaz-backup-${user?.mobile ?? "user"}-${DateX.ymd(DateTime.now())}.json';
    final file = File(p.join(dir.path, fname));
    await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(payload));
    await Share.shareXFiles([XFile(file.path)],
        subject: 'My Namaz Backup');
  }

  /// Imports a previously-exported JSON file by absolute path.
  /// Returns the number of records imported.
  static Future<int> importJsonFromFile(String filePath) async {
    final raw = await File(filePath).readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final profileMap = data['profile'] as Map<String, dynamic>?;
    final records =
        (data['records'] as List).cast<Map<String, dynamic>>();

    if (profileMap != null) {
      final profile = UserProfile.fromMap(profileMap);
      await UserDao().upsert(profile);
    }
    int imported = 0;
    for (final r in records) {
      final rec = PrayerRecord.fromMap(r);
      await PrayerDao().upsert(rec);
      imported++;
    }
    return imported;
  }
}
