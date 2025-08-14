import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
  const DestinationPage({super.key, required this.ball});

  Future<void> _pickBg(WidgetRef ref) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x != null) {
      ref.read(entryBgProvider.notifier).state = File(x.path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isEntries = ball.navIndex == 1;
    final File? bgFile = isEntries ? ref.watch(entryBgProvider) : null;

    final Widget background = isEntries
        ? (bgFile != null
            ? Image.file(bgFile, fit: BoxFit.cover)
            : Container(color: ball.color))
        : Container(color: ball.color);

    final Widget body = isEntries
        ? const EntriesListBody()
        : const JournalListBody();

    return Scaffold(
      appBar: isEntries
          ? AppBar(
              title: const Text('Entries'),
              actions: [
                IconButton(
                  tooltip: 'Change background',
                  icon: const Icon(Icons.photo),
                  onPressed: () => _pickBg(ref),
                ),
              ],
            )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          background,
          if (isEntries) Container(color: Colors.black.withOpacity(0.35)),
          body,
        ],
      ),
      floatingActionButton: switch (ball.navIndex) {
        1 => const EntriesFab(),
        2 => const JournalFab(),
        _ => null,
      },
    );
  }
}

/* ───────────── FABs (kept here) ───────────── */
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
              ctx,
              MaterialPageRoute(
                  builder: (_) => const AddJournalEntryPage()));
          ref.invalidate(journalsFutureProvider);
        },
        child: const Icon(Icons.add),
      );
}
