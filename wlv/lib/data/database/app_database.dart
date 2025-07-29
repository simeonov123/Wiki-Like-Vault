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
      version: 3, // ⬅️ bump to v3
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  /* ── Callbacks ────────────────────────────────────────────────────────── */
  Future _onCreate(Database db, int version) async {
    // notes
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL
      )
    ''');

    // movies
    await db.execute('''
      CREATE TABLE movies(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        year INTEGER NOT NULL
      )
    ''');

    // NEW v3 tables
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
  }

  Future _createEntryTable(Database db) async => db.execute('''
      CREATE TABLE entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        images TEXT NOT NULL,     -- JSON list
        links TEXT NOT NULL,      -- JSON list
        created_at INTEGER NOT NULL,
        rating INTEGER NOT NULL
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

  /* ── Desktop FFI ──────────────────────────────────────────────────────── */
  void _initFfiIfNeeded() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }
}
