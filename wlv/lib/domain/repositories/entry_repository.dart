import '../entities/entry.dart';

abstract class EntryRepository {
  Future<Entry> save(Entry e);
  Future<List<Entry>> findAll();
}
