import 'package:sqflite/sqflite.dart';
import '../models/prayer_record.dart';
import '../utils/date_utils.dart';
import 'database.dart';

class PrayerDao {
  Future<PrayerRecord?> getByDate(DateTime date) async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query(
      'prayer_record',
      where: 'date = ?',
      whereArgs: [DateX.ymd(date)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PrayerRecord.fromMap(rows.first);
  }

  Future<List<PrayerRecord>> getRange(DateTime start, DateTime end) async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query(
      'prayer_record',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [DateX.ymd(start), DateX.ymd(end)],
      orderBy: 'date DESC',
    );
    return rows.map(PrayerRecord.fromMap).toList();
  }

  Future<List<PrayerRecord>> getAll() async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query('prayer_record', orderBy: 'date DESC');
    return rows.map(PrayerRecord.fromMap).toList();
  }

  Future<PrayerRecord> upsert(PrayerRecord r) async {
    final db = await AppDatabase.instance.db;
    final existing = await db.query(
      'prayer_record',
      where: 'date = ?',
      whereArgs: [DateX.ymd(r.date)],
      limit: 1,
    );
    if (existing.isEmpty) {
      final id = await db.insert('prayer_record', r.toMap());
      return PrayerRecord.fromMap({...r.toMap(), 'id': id});
    } else {
      await db.update(
        'prayer_record',
        r.toMap(),
        where: 'date = ?',
        whereArgs: [DateX.ymd(r.date)],
      );
      return r;
    }
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.instance.db;
    await db.delete('prayer_record');
  }

  Future<void> seedIfEmpty() async {
    final db = await AppDatabase.instance.db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM prayer_record'),
    );
    if ((count ?? 0) > 0) return;

    final now = DateTime.now();
    for (int i = 1; i <= 30; i++) {
      final d = DateTime(now.year, now.month, now.day - i);
      // Pseudo-realistic pattern: Fajr ~60%, others 80-95%
      final seed = d.day * 7 + d.month;
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
      await db.insert('prayer_record', r.toMap());
    }
  }
}
