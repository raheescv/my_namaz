import 'package:sqflite/sqflite.dart';

import '../models/prayer_record.dart';
import '../utils/date_utils.dart';
import 'database.dart';

class PrayerDao {
  Future<PrayerRecord?> getByDate(int userId, DateTime date) async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query(
      'prayer_record',
      where: 'userId = ? AND date = ?',
      whereArgs: [userId, DateX.ymd(date)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PrayerRecord.fromMap(rows.first);
  }

  Future<List<PrayerRecord>> getRange(
      int userId, DateTime start, DateTime end) async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query(
      'prayer_record',
      where: 'userId = ? AND date BETWEEN ? AND ?',
      whereArgs: [userId, DateX.ymd(start), DateX.ymd(end)],
      orderBy: 'date DESC',
    );
    return rows.map(PrayerRecord.fromMap).toList();
  }

  Future<List<PrayerRecord>> getAllForUser(int userId) async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query(
      'prayer_record',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return rows.map(PrayerRecord.fromMap).toList();
  }

  Future<PrayerRecord> upsert(int userId, PrayerRecord r) async {
    final db = await AppDatabase.instance.db;
    final existing = await db.query(
      'prayer_record',
      where: 'userId = ? AND date = ?',
      whereArgs: [userId, DateX.ymd(r.date)],
      limit: 1,
    );
    final map = r.toMap()..['userId'] = userId;
    if (existing.isEmpty) {
      final id = await db.insert('prayer_record', map);
      return PrayerRecord.fromMap({...map, 'id': id});
    } else {
      await db.update(
        'prayer_record',
        map,
        where: 'userId = ? AND date = ?',
        whereArgs: [userId, DateX.ymd(r.date)],
      );
      return r;
    }
  }

  Future<void> deleteAllForUser(int userId) async {
    final db = await AppDatabase.instance.db;
    await db.delete('prayer_record',
        where: 'userId = ?', whereArgs: [userId]);
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.instance.db;
    await db.delete('prayer_record');
  }

  /// Seed sample data for a given user if they have none yet.
  Future<void> seedIfEmpty(int userId) async {
    final db = await AppDatabase.instance.db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
          'SELECT COUNT(*) FROM prayer_record WHERE userId = ?', [userId]),
    );
    if ((count ?? 0) > 0) return;

    final now = DateTime.now();
    for (int i = 1; i <= 30; i++) {
      final d = DateTime(now.year, now.month, now.day - i);
      final seed = d.day * 7 + d.month + userId;
      bool by(int prob) => (seed + prob) % 100 < prob;
      final r = PrayerRecord(
        date: d,
        fajr: by(60),
        dhuhr: by(90),
        asr: by(85),
        maghrib: by(95),
        isha: by(80),
        createdAt: d,
        updatedAt: d,
      );
      final map = r.toMap()..['userId'] = userId;
      await db.insert('prayer_record', map);
    }
  }
}
