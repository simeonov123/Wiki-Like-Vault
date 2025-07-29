import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

class GetJournalEntries {
  final JournalRepository _repo;
  GetJournalEntries(this._repo);

  Future<List<JournalEntry>> call() => _repo.findAll();
}
