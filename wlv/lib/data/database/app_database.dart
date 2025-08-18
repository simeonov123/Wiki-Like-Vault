import 'dart:io' show Platform;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _initFfiIfNeeded();

    final path = join(await getDatabasesPath(), 'vault.db');
    _db = await openDatabase(
      path,
      version: 5, // ⬅️ bumped to v5 for bg_color_hex migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE movies(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        year INTEGER NOT NULL
      )
    ''');

    await _createEntryTable(db);
    await _createJournalTable(db);
  }

  Future _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute('''
        CREATE TABLE movies(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          year INTEGER NOT NULL
        )
      ''');
    }
    if (oldV < 3) {
      await _createEntryTable(db);
      await _createJournalTable(db);
    }
    if (oldV < 4) {
      // legacy column (int) – safe to leave
      await db.execute('ALTER TABLE entries ADD COLUMN bg_color INTEGER');
    }
    if (oldV < 5) {
      // new column using HEX string
      await db.execute(
        "ALTER TABLE entries ADD COLUMN bg_color_hex TEXT DEFAULT '#FFFFFFFF'"
      );
    }
  }

  Future _createEntryTable(Database db) async => db.execute('''
      CREATE TABLE entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        images TEXT NOT NULL,
        links TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        rating INTEGER NOT NULL,
        bg_color_hex TEXT DEFAULT '#FFFFFFFF'
      )
    ''');

  Future _createJournalTable(Database db) async => db.execute('''
      CREATE TABLE journals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        mood INTEGER NOT NULL
      )
    ''');

  void _initFfiIfNeeded() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }
}
