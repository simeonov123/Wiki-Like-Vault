import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/entry_providers.dart';
import '../providers/entry_bg_provider.dart';

class EntriesListBody extends ConsumerWidget {
  const EntriesListBody({super.key});

  Future<void> _pickBg(BuildContext ctx, WidgetRef ref) async {
    final picker = ImagePicker();
    final XFile? x = await picker.pickImage(source: ImageSource.gallery);
    if (x != null) ref.read(entryBgProvider.notifier).state = File(x.path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(entriesFutureProvider);
    final bgFile = ref.watch(entryBgProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background image (if any) ────────────────────────────────
        if (bgFile != null)
          Image.file(bgFile,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity),

        // ── Semi-transparent scrim so text stays readable ────────────
        Container(color: Colors.black.withOpacity(0.35)),

        // ── Entries list (or empty / loading states) ─────────────────
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (entries) => entries.isEmpty
              ? const Center(child: Text('No entries yet'))
              : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e = entries[i];
              return Card(
                color: Colors.white70,
                child: ListTile(
                  leading: Text(e.category.name),
                  title: Text(e.title),
                  subtitle: Text('★ ${e.rating}  –  ${e.description}'),
                ),
              );
            },
          ),
        ),

        // ── Floating action button to change background ──────────────
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'pickBg',
            tooltip: 'Change background',
            onPressed: () => _pickBg(context, ref),
            child: const Icon(Icons.photo),
          ),
        ),
      ],
    );
  }
}
