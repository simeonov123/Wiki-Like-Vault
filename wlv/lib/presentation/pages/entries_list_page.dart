import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/entry_providers.dart';

class EntriesListBody extends ConsumerWidget {
  const EntriesListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(entriesFutureProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (entries) => entries.isEmpty
          ? const Center(child: Text('No entries yet'))
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final e = entries[i];
                return ListTile(
                  leading: Text(e.category.name),
                  title: Text(e.title),
                  subtitle: Text('★ ${e.rating}  –  ${e.description}'),
                );
              },
            ),
    );
  }
}
