import '../../domain/entities/note.dart';
import '../database/app_database.dart';

class NoteDao {
  static const _table = 'notes';

  Future<int> insert(Note n) async =>
      (await AppDatabase.instance.db).insert(_table, {
        'title': n.title,
        'content': n.content,
      });

  Future<List<Note>> fetchAll() async {
    final rows =
        await (await AppDatabase.instance.db).query(_table, orderBy: 'id DESC');
    return rows
        .map((r) => Note(
              id: r['id'] as int,
              title: r['title'] as String,
              content: r['content'] as String,
            ))
        .toList();
  }
}
