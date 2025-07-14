import '../entities/note.dart';

abstract class NoteRepository {
  Future<Note> save(Note n);
  Future<List<Note>> findAll();
}
