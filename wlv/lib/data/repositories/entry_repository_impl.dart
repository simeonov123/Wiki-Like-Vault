import '../../domain/entities/entry.dart';
import '../../domain/repositories/entry_repository.dart';
import '../dao/entry_dao.dart';

class EntryRepositoryImpl implements EntryRepository {
  final _dao = EntryDao();

  @override
  Future<Entry> save(Entry e) async => e.copyWith(id: await _dao.insert(e));

  @override
  Future<List<Entry>> findAll() => _dao.fetchAll();
}
