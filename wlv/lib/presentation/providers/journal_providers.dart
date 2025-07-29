import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/journal_repository_impl.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/usecases/add_journal_entry.dart';
import '../../domain/usecases/get_journal_entries.dart';

final _journalRepo = Provider((_) => JournalRepositoryImpl());

final addJournalUcProvider =
    Provider((ref) => AddJournalEntry(ref.watch(_journalRepo)));

final getJournalUcProvider =
    Provider((ref) => GetJournalEntries(ref.watch(_journalRepo)));

final journalsFutureProvider = FutureProvider<List<JournalEntry>>(
    (ref) => ref.watch(getJournalUcProvider).call());
