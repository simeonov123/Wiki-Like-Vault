import '../entities/entry.dart';

abstract class EntryRepository {
  Future<Entry> save(Entry e);               // insert
  Future<void> saveAll(List<Entry> items);   // bulk insert (seeding)
  Future<Entry> update(Entry e);             // update by id (id required)
  Future<void>  deleteById(int id);          // delete by id
  Future<List<Entry>> findAll();             // fetch all (ordered newest first)
}
