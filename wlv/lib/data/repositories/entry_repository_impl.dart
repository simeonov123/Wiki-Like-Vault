import '../../domain/entities/entry.dart';
import '../../domain/repositories/entry_repository.dart';
import '../dao/entry_dao.dart';

class EntryRepositoryImpl implements EntryRepository {
  final _dao = EntryDao();

  @override
Future<Entry> save(Entry e) async {
  final id = await _dao.insert(e);
  return e.copyWith(id: id, bgColorHex: e.bgColorHex);

}

  @override
  Future<void> saveAll(List<Entry> items) async {
    await _dao.insertMany(items);
  }

  @override
  Future<Entry> update(Entry e) async {
    if (e.id == null) {
      throw ArgumentError('Entry.id must not be null for update');
    }
    await _dao.update(e);
    return e;
  }

  @override
  Future<void> deleteById(int id) => _dao.deleteById(id);

  @override
  Future<List<Entry>> findAll() => _dao.fetchAll();
}
