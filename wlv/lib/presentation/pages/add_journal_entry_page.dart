import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/entities/mood.dart';
import '../providers/journal_providers.dart';

class AddJournalEntryPage extends ConsumerStatefulWidget {
  const AddJournalEntryPage({super.key});
  @override
  ConsumerState<AddJournalEntryPage> createState() =>
      _AddJournalEntryPageState();
}

class _AddJournalEntryPageState extends ConsumerState<AddJournalEntryPage> {
  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  Mood _mood = Mood.neutral;

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New Journal Entry')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            DropdownButtonFormField<Mood>(
              value: _mood,
              onChanged: (m) => setState(() => _mood = m!),
              items: Mood.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Mood'),
            ),
            TextField(
              controller: _titleC,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            Expanded(
              child: TextField(
                controller: _descC,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: null,
                expands: true,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: () async {
                final t = _titleC.text.trim();
                final d = _descC.text.trim();
                if (t.isEmpty) return;
                await ref.read(addJournalUcProvider).call(
                      JournalEntry(
                        date: DateTime.now(),
                        title: t,
                        description: d,
                        mood: _mood,
                      ),
                    );
                ref.invalidate(journalsFutureProvider);
                if (mounted) Navigator.pop(context);
              },
            )
          ]),
        ),
      );
}
