import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/vault_bottom_nav_bar.dart';
import '../providers/note_providers.dart';
import '../providers/movie_providers.dart';
import 'notes_list_page.dart';
import 'movies_list_page.dart';
import 'add_note_page.dart';
import 'add_movie_page.dart';

/// Root page that owns the single Scaffold and the bottom navigation bar.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 0;

  // Tab bodies (no Scaffolds inside)
  static const _tabs = [NotesListBody(), MoviesListBody()];
  static const _titles = ['My Notes', 'Movies'];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_titles[_index])),
        body: IndexedStack(index: _index, children: _tabs),
        floatingActionButton: _index == 0
            ? FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddNotePage()));
                  ref.invalidate(notesFutureProvider);
                },
                child: const Icon(Icons.add),
              )
            : FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddMoviePage()));
                  ref.invalidate(moviesFutureProvider);
                },
                child: const Icon(Icons.add),
              ),
        bottomNavigationBar: VaultBottomNavBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      );
}
