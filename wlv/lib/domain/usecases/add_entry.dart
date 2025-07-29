import '../entities/entry.dart';
import '../repositories/entry_repository.dart';

class AddEntry {
  final EntryRepository _repo;
  AddEntry(this._repo);

  Future<Entry> call(Entry e) => _repo.save(e);
}
