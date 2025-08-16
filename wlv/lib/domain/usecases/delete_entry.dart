import '../repositories/entry_repository.dart';

class DeleteEntry {
  final EntryRepository _repo;
  DeleteEntry(this._repo);

  Future<void> call(int id) => _repo.deleteById(id);
}
