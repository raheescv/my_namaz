import 'package:sqflite/sqflite.dart';

import '../models/user_profile.dart';
import 'database.dart';

class UserDao {
  Future<UserProfile?> getById(int id) async {
    final db = await AppDatabase.instance.db;
    final rows =
        await db.query('user_profile', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<UserProfile?> getByMobile(String countryCode, String mobile) async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query(
      'user_profile',
      where: 'countryCode = ? AND mobile = ?',
      whereArgs: [countryCode, mobile],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<List<UserProfile>> getAll() async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query('user_profile', orderBy: 'updatedAt DESC');
    return rows.map(UserProfile.fromMap).toList();
  }

  /// Insert if no user exists with this (countryCode, mobile),
  /// otherwise update the existing row. Returns the saved profile with id set.
  Future<UserProfile> upsertByMobile(UserProfile p) async {
    final db = await AppDatabase.instance.db;
    final existing = await getByMobile(p.countryCode, p.mobile);
    if (existing == null) {
      final id = await db.insert(
        'user_profile',
        p.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return p.copyWith(id: id);
    } else {
      final merged = p.copyWith(id: existing.id);
      await db.update(
        'user_profile',
        merged.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return merged;
    }
  }

  /// Update an already-persisted profile in place.
  /// Distinct from upsertByMobile because here we may be changing the mobile
  /// or other fields on a known user id.
  Future<UserProfile> updateById(UserProfile p) async {
    assert(p.id != null, 'updateById requires id');
    final db = await AppDatabase.instance.db;
    await db.update(
      'user_profile',
      p.toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
    return p;
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.instance.db;
    await db.delete('user_profile');
  }

  Future<void> deleteById(int id) async {
    final db = await AppDatabase.instance.db;
    await db.delete('user_profile', where: 'id = ?', whereArgs: [id]);
  }
}
