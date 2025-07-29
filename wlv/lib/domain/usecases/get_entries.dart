import '../entities/entry.dart';
import '../repositories/entry_repository.dart';

class GetEntries {
  final EntryRepository _repo;
  GetEntries(this._repo);

  Future<List<Entry>> call() => _repo.findAll();
}
