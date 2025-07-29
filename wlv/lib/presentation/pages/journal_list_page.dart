import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/journal_providers.dart';

class JournalListBody extends ConsumerWidget {
  const JournalListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(journalsFutureProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (entries) => entries.isEmpty
          ? const Center(child: Text('Start journaling!'))
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final j = entries[i];
                return ListTile(
                  leading: Text(j.mood.name),
                  title: Text(j.title),
                  subtitle: Text(j.date.toLocal().toString().split(' ').first),
                );
              }),
    );
  }
}
