import 'dart:convert';
import '../../domain/entities/entry.dart';
import '../../domain/entities/category.dart';
import '../database/app_database.dart';

class EntryDao {
  static const _table = 'entries';

  Future<int> insert(Entry e) async =>
      (await AppDatabase.instance.db).insert(_table, {
        'category': e.category.index,
        'title': e.title,
        'description': e.description,
        'images': jsonEncode(e.imagePaths),
        'links': jsonEncode(e.links),
        'created_at': e.createdAt.millisecondsSinceEpoch,
        'rating': e.rating,
      });

  /// Bulk insert used by the seeder.
  Future<void> insertMany(List<Entry> items) async {
    final db = await AppDatabase.instance.db;
    await db.transaction((txn) async {
      for (final e in items) {
        await txn.insert(_table, {
          'category': e.category.index,
          'title': e.title,
          'description': e.description,
          'images': jsonEncode(e.imagePaths),
          'links': jsonEncode(e.links),
          'created_at': e.createdAt.millisecondsSinceEpoch,
          'rating': e.rating,
        });
      }
    });
  }

  Future<int> update(Entry e) async {
    return (await AppDatabase.instance.db).update(
      _table,
      {
        'category': e.category.index,
        'title': e.title,
        'description': e.description,
        'images': jsonEncode(e.imagePaths),
        'links': jsonEncode(e.links),
        'created_at': e.createdAt.millisecondsSinceEpoch,
        'rating': e.rating,
      },
      where: 'id = ?',
      whereArgs: [e.id],
    );
  }

  Future<void> deleteById(int id) async {
    await (await AppDatabase.instance.db)
        .delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Entry>> fetchAll() async {
    final rows =
        await (await AppDatabase.instance.db).query(_table, orderBy: 'id DESC');
    return rows
        .map((r) => Entry(
              id: r['id'] as int,
              category: Category.values[r['category'] as int],
              title: r['title'] as String,
              description: r['description'] as String,
              imagePaths: List<String>.from(jsonDecode(r['images'] as String)),
              links: List<String>.from(jsonDecode(r['links'] as String)),
              createdAt:
                  DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
              rating: r['rating'] as int,
            ))
        .toList();
  }
}
