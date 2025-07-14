import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../dao/note_dao.dart';

class NoteRepositoryImpl implements NoteRepository {
  final _dao = NoteDao();

  @override
  Future<Note> save(Note n) async => n.copyWith(id: await _dao.insert(n));

  @override
  Future<List<Note>> findAll() => _dao.fetchAll();
}
