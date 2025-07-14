import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/note_providers.dart';

/// Body-only widget; no Scaffold.
class NotesListBody extends ConsumerWidget {
  const NotesListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesFutureProvider);

    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (notes) => notes.isEmpty
          ? const Center(child: Text('Nothing here yet – add one!'))
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final n = notes[i];
                return Card(
                  child: ListTile(
                    title: Text(n.title),
                    subtitle: Text(
                      n.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
