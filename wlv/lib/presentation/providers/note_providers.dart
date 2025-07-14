import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/get_notes.dart';

// Low-level singleton repository
final _noteRepoProvider =
    Provider<NoteRepositoryImpl>((_) => NoteRepositoryImpl());

// Use-cases exposed to UI
final addNoteUseCaseProvider =
    Provider<AddNote>((ref) => AddNote(ref.watch(_noteRepoProvider)));

final getNotesUseCaseProvider =
    Provider<GetNotes>((ref) => GetNotes(ref.watch(_noteRepoProvider)));

// Notes list as an auto-refreshing future
final notesFutureProvider = FutureProvider<List<Note>>((ref) async {
  return ref.watch(getNotesUseCaseProvider).call();
});
