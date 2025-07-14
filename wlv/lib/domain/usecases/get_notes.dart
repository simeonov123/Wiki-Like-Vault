import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetNotes {
  final NoteRepository _repo;
  GetNotes(this._repo);

  Future<List<Note>> call() => _repo.findAll();
}
