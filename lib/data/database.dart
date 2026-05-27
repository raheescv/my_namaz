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
    // Desktop platforms (macOS / Windows / Linux) need the FFI backend.
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
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE user_profile (
            id INTEGER PRIMARY KEY,
            mobile TEXT NOT NULL,
            countryCode TEXT NOT NULL,
            name TEXT NOT NULL,
            email TEXT,
            avatarPath TEXT,
            city TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE prayer_record (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            fajr INTEGER NOT NULL DEFAULT 0,
            dhuhr INTEGER NOT NULL DEFAULT 0,
            asr INTEGER NOT NULL DEFAULT 0,
            maghrib INTEGER NOT NULL DEFAULT 0,
            isha INTEGER NOT NULL DEFAULT 0,
            notes TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_prayer_date ON prayer_record(date)',
        );
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
