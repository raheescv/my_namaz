import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static bool _ffiInitialized = false;
  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    if (!_ffiInitialized &&
        (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiInitialized = true;
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'my_namaz.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createV2(db);
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await _migrateV1ToV2(db);
        }
      },
    );
  }

  Future<void> _createV2(Database db) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mobile TEXT NOT NULL,
        countryCode TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT,
        avatarPath TEXT,
        city TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        UNIQUE(mobile, countryCode)
      )
    ''');
    await db.execute('''
      CREATE TABLE prayer_record (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        date TEXT NOT NULL,
        fajr INTEGER NOT NULL DEFAULT 0,
        dhuhr INTEGER NOT NULL DEFAULT 0,
        asr INTEGER NOT NULL DEFAULT 0,
        maghrib INTEGER NOT NULL DEFAULT 0,
        isha INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        UNIQUE(userId, date),
        FOREIGN KEY(userId) REFERENCES user_profile(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_prayer_user_date ON prayer_record(userId, date)',
    );
  }

  /// v1 schema:
  ///   user_profile (id PK fixed=1, mobile, countryCode, name, ...)
  ///   prayer_record (no userId column)
  ///
  /// Migration: keep the single existing user, assign all existing
  /// records to that user, then enforce the new constraints.
  Future<void> _migrateV1ToV2(Database db) async {
    final existingUsers = await db.query('user_profile');
    final existingRecords = await db.query('prayer_record');

    await db.execute('ALTER TABLE user_profile RENAME TO user_profile_old');
    await db.execute('ALTER TABLE prayer_record RENAME TO prayer_record_old');

    await _createV2(db);

    int? migratedUserId;
    if (existingUsers.isNotEmpty) {
      final u = existingUsers.first;
      migratedUserId = await db.insert('user_profile', {
        'mobile': u['mobile'],
        'countryCode': u['countryCode'],
        'name': u['name'],
        'email': u['email'],
        'avatarPath': u['avatarPath'],
        'city': u['city'],
        'createdAt': u['createdAt'],
        'updatedAt': u['updatedAt'],
      });
    }
    if (migratedUserId != null) {
      for (final r in existingRecords) {
        await db.insert('prayer_record', {
          'userId': migratedUserId,
          'date': r['date'],
          'fajr': r['fajr'],
          'dhuhr': r['dhuhr'],
          'asr': r['asr'],
          'maghrib': r['maghrib'],
          'isha': r['isha'],
          'notes': r['notes'],
          'createdAt': r['createdAt'],
          'updatedAt': r['updatedAt'],
        });
      }
    }

    await db.execute('DROP TABLE user_profile_old');
    await db.execute('DROP TABLE prayer_record_old');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
