import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';
import '../dao/journal_entry_dao.dart';

class JournalRepositoryImpl implements JournalRepository {
  final _dao = JournalEntryDao();

  @override
  Future<JournalEntry> save(JournalEntry j) async =>
      j.copyWith(id: await _dao.insert(j));

  @override
  Future<List<JournalEntry>> findAll() => _dao.fetchAll();
}
