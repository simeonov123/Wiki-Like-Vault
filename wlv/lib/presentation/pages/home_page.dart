import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/vault_bottom_nav_bar.dart';
import '../providers/note_providers.dart';
import '../providers/movie_providers.dart';
import '../providers/entry_providers.dart';
import '../providers/journal_providers.dart';
import 'notes_list_page.dart';
import 'movies_list_page.dart';
import 'entries_list_page.dart';
import 'journal_list_page.dart';
import 'add_note_page.dart';
import 'add_movie_page.dart';
import 'add_entry_page.dart';
import 'add_journal_entry_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _idx = 0;

  static const _tabs = [
    NotesListBody(),
    MoviesListBody(),
    EntriesListBody(),
    JournalListBody(),
  ];
  static const _titles = ['Notes', 'Movies', 'Entries', 'Journal'];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_titles[_idx])),
        body: IndexedStack(index: _idx, children: _tabs),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () async {
            switch (_idx) {
              case 0:
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddNotePage()));
                ref.invalidate(notesFutureProvider);
                break;
              case 1:
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddMoviePage()));
                ref.invalidate(moviesFutureProvider);
                break;
              case 2:
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddEntryPage()));
                ref.invalidate(entriesFutureProvider);
                break;
              case 3:
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddJournalEntryPage()));
                ref.invalidate(journalsFutureProvider);
                break;
            }
          },
        ),
        bottomNavigationBar: VaultBottomNavBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
        ),
      );
}
