import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/vault_bottom_nav_bar.dart';
import '../widgets/floating_nav_balls.dart';
import '../providers/entry_providers.dart';
import '../providers/journal_providers.dart';
import 'home_message_body.dart';
import 'entries_list_page.dart';
import 'journal_list_page.dart';
import 'add_entry_page.dart';
import 'add_journal_entry_page.dart';
import '../providers/entry_bg_provider.dart';
import 'entries_filter_menu.dart';

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

  Future<void> _pickBg() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x != null) {
      await ref.read(entryBgProvider.notifier).setBackgroundFromPath(x.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Background updated')),
        );
      }
    }
  }

  Future<void> _clearBg() async {
    await ref.read(entryBgProvider.notifier).clearBackground();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Background reset')),
      );
    }
  }

  Future<void> _seed55() async {
    ref.invalidate(entriesFutureProvider); // refresh list
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seeded 55 mock entries')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final File? bgFile = ref.watch(entryBgProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_idx]),
        actions: [
          if (_idx == 1) ...[
            IconButton(
              tooltip: 'Filter & sort',
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: () => showEntriesFilterSheet(context: context, ref: ref),
            ),
            IconButton(
              tooltip: 'Change background',
              icon: const Icon(Icons.photo),
              onPressed: _pickBg,
            ),
            IconButton(
              tooltip: 'Reset background',
              icon: const Icon(Icons.refresh),
              onPressed: _clearBg,
            ),
            if (kDebugMode)
              IconButton(
                tooltip: 'Seed 55 mock entries',
                onPressed: _seed55,
                icon: const Icon(Icons.cloud_download_rounded),
              ),
          ],
        ],
      ),
      body: Stack(
        children: [
          if (_idx == 1) ...[
            if (bgFile != null)
              Positioned.fill(
                child: Image.file(
                  bgFile,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.35)),
            ),
          ],
          IndexedStack(index: _idx, children: _tabs),
          if (_idx == 0) const FloatingNavBalls(),
        ],
      ),
      floatingActionButton: switch (_idx) {
        1 => FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEntryPage()),
              );
              ref.invalidate(entriesFutureProvider);
            },
            child: const Icon(Icons.add),
          ),
        2 => FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddJournalEntryPage()),
              );
              ref.invalidate(journalsFutureProvider);
            },
            child: const Icon(Icons.add),
          ),
        _ => null,
      },
      bottomNavigationBar: _idx == 0
          ? null
          : VaultBottomNavBar(
              currentIndex: _idx,
              onTap: (i) => setState(() => _idx = i),
            ),
    );
  }
}
