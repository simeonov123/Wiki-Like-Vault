import '../entities/entry.dart';
import '../repositories/entry_repository.dart';

class UpdateEntry {
  final EntryRepository _repo;
  UpdateEntry(this._repo);

  Future<Entry> call(Entry e) => _repo.update(e);
}
