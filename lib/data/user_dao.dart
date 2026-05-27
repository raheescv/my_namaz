import 'package:sqflite/sqflite.dart';
import '../models/user_profile.dart';
import 'database.dart';

class UserDao {
  Future<UserProfile?> get() async {
    final db = await AppDatabase.instance.db;
    final rows = await db.query('user_profile', limit: 1);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<void> upsert(UserProfile p) async {
    final db = await AppDatabase.instance.db;
    await db.insert(
      'user_profile',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAll() async {
    final db = await AppDatabase.instance.db;
    await db.delete('user_profile');
  }
}
