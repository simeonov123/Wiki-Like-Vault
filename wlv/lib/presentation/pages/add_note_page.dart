import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/note_providers.dart';

class AddNotePage extends ConsumerStatefulWidget {
  const AddNotePage({super.key});
  @override
  ConsumerState<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends ConsumerState<AddNotePage> {
  final _titleC = TextEditingController();
  final _contentC = TextEditingController();

  @override
  void dispose() {
    _titleC.dispose();
    _contentC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Note')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleC,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentC,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: null,
                expands: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                onPressed: () async {
                  final t = _titleC.text.trim();
                  final c = _contentC.text.trim();
                  if (t.isEmpty || c.isEmpty) return;

                  await ref.read(addNoteUseCaseProvider).call(t, c);

                  // Tell Riverpod to refresh the notes list
                  ref.invalidate(notesFutureProvider);

                  if (mounted) Navigator.of(context).pop();
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
