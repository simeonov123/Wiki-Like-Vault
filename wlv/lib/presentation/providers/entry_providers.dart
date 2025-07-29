import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/entry_repository_impl.dart';
import '../../domain/entities/entry.dart';
import '../../domain/usecases/add_entry.dart';
import '../../domain/usecases/get_entries.dart';

final _entryRepo = Provider((_) => EntryRepositoryImpl());

final addEntryUcProvider = Provider((ref) => AddEntry(ref.watch(_entryRepo)));

final getEntriesUcProvider =
    Provider((ref) => GetEntries(ref.watch(_entryRepo)));

final entriesFutureProvider = FutureProvider<List<Entry>>(
    (ref) => ref.watch(getEntriesUcProvider).call());
