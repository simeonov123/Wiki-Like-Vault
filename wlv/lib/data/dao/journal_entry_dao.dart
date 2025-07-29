import '../../domain/entities/journal_entry.dart';
import '../../domain/entities/mood.dart';
import '../database/app_database.dart';

class JournalEntryDao {
  static const _table = 'journals';

  Future<int> insert(JournalEntry j) async =>
      (await AppDatabase.instance.db).insert(_table, {
        'date': j.date.millisecondsSinceEpoch,
        'title': j.title,
        'description': j.description,
        'mood': j.mood.index,
      });

  Future<List<JournalEntry>> fetchAll() async {
    final rows = await (await AppDatabase.instance.db)
        .query(_table, orderBy: 'date DESC');
    return rows
        .map((r) => JournalEntry(
              id: r['id'] as int,
              date: DateTime.fromMillisecondsSinceEpoch(r['date'] as int),
              title: r['title'] as String,
              description: r['description'] as String,
              mood: Mood.values[r['mood'] as int],
            ))
        .toList();
  }
}
