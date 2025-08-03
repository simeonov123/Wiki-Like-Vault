import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/ball.dart';
import '../providers/entry_bg_provider.dart';
import '../providers/entry_providers.dart';
import '../providers/journal_providers.dart';
import 'entries_list_page.dart';
import 'journal_list_page.dart';
import 'add_entry_page.dart';
import 'add_journal_entry_page.dart';

class DestinationPage extends ConsumerWidget {
  final Ball ball;
  const DestinationPage({Key? key, required this.ball}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isEntries = ball.navIndex == 1;
    final File? bgFile   = isEntries ? ref.watch(entryBgProvider) : null;

    final Widget background = bgFile != null
        ? Image.file(bgFile, fit: BoxFit.cover)
        : Container(color: ball.color);

    final Widget body =
    isEntries ? const EntriesListBody() : const JournalListBody();

    return Scaffold(
      appBar: isEntries ? AppBar(title: const Text('Entries')) : null,
      body: Stack(fit: StackFit.expand, children: [background, body]),
      floatingActionButton: switch (ball.navIndex) {
        1 => const EntriesFab(),
        2 => const JournalFab(),
        _ => null,
      },
    );
  }
}

/* ───────────── FABs (moved here) ───────────── */
class EntriesFab extends ConsumerWidget {
  const EntriesFab({super.key});
  @override
  Widget build(BuildContext ctx, WidgetRef ref) => FloatingActionButton(
    onPressed: () async {
      await Navigator.push(
          ctx, MaterialPageRoute(builder: (_) => const AddEntryPage()));
      ref.invalidate(entriesFutureProvider);
    },
    child: const Icon(Icons.add),
  );
}

class JournalFab extends ConsumerWidget {
  const JournalFab({super.key});
  @override
  Widget build(BuildContext ctx, WidgetRef ref) => FloatingActionButton(
    onPressed: () async {
      await Navigator.push(
          ctx, MaterialPageRoute(builder: (_) => const AddJournalEntryPage()));
      ref.invalidate(journalsFutureProvider);
    },
    child: const Icon(Icons.add),
  );
}
