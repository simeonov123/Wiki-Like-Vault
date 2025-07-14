import '../entities/note.dart';
import '../repositories/note_repository.dart';

class AddNote {
  final NoteRepository _repo;
  AddNote(this._repo);

  Future<Note> call(String title, String content) =>
      _repo.save(Note(title: title, content: content));
}
