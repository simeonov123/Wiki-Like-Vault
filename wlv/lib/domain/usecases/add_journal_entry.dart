import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

class AddJournalEntry {
  final JournalRepository _repo;
  AddJournalEntry(this._repo);

  Future<JournalEntry> call(JournalEntry j) => _repo.save(j);
}
