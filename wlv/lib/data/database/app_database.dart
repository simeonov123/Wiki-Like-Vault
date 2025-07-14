import 'dart:io' show Platform;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase._(); // singleton
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _initFfiIfNeeded(); // desktop support

    final path = join(await getDatabasesPath(), 'vault.db');
    _db = await openDatabase(
      path,
      version: 2, // ← bumped to 2
      onCreate: _onCreate, // brand-new install
      onUpgrade: _onUpgrade, // migrations
    );
    return _db!;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Callbacks
  // ─────────────────────────────────────────────────────────────────────────
  Future _onCreate(Database db, int version) async {
    // v2 schema straight away (notes + movies)
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
  }

  Future _onUpgrade(Database db, int oldV, int newV) async {
    // step-by-step migrations
    if (oldV < 2) {
      await db.execute('''
        CREATE TABLE movies(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          year INTEGER NOT NULL
        )
      ''');
    }
    // Future: if (oldV < 3) { … }  etc.
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Desktop FFI helper
  // ─────────────────────────────────────────────────────────────────────────
  void _initFfiIfNeeded() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }
}
