import '../entities/journal_entry.dart';

abstract class JournalRepository {
  Future<JournalEntry> save(JournalEntry j);
  Future<List<JournalEntry>> findAll();
}
