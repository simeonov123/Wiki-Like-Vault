import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/vault_bottom_nav_bar.dart';
import '../widgets/floating_nav_balls.dart';
import '../providers/entry_providers.dart';
import '../providers/journal_providers.dart';
import 'home_message_body.dart';
import 'entries_list_page.dart';
import 'journal_list_page.dart';
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
    HomeMessageBody(),
    EntriesListBody(),
    JournalListBody(),
  ];
  static const _titles = ['Home', 'Entries', 'Journal'];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_titles[_idx])),
        body: Stack(
          children: [
            IndexedStack(index: _idx, children: _tabs),
            if (_idx == 0) const FloatingNavBalls(),
          ],
        ),
        floatingActionButton: switch (_idx) {
          1 => FloatingActionButton(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddEntryPage()));
                ref.invalidate(entriesFutureProvider);
              },
              child: const Icon(Icons.add),
            ),
          2 => FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddJournalEntryPage()));
                ref.invalidate(journalsFutureProvider);
              },
              child: const Icon(Icons.add),
            ),
          _ => null,
        },
        // show bottom bar only when NOT on Home
        bottomNavigationBar: _idx == 0
            ? null
            : VaultBottomNavBar(
                currentIndex: _idx,
                onTap: (i) => setState(() => _idx = i),
              ),
      );
}
