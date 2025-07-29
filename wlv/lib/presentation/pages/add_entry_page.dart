import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/entry.dart';
import '../providers/entry_providers.dart';

class AddEntryPage extends ConsumerStatefulWidget {
  const AddEntryPage({super.key});
  @override
  ConsumerState<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends ConsumerState<AddEntryPage> {
  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  double _rating = 5;
  Category _cat = Category.book;

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New Entry')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(children: [
            DropdownButtonFormField<Category>(
              value: _cat,
              onChanged: (c) => setState(() => _cat = c!),
              items: Category.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: _titleC,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descC,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Text('Rating: ${_rating.round()}'),
            Slider(
              value: _rating,
              min: 1,
              max: 10,
              divisions: 9,
              label: _rating.round().toString(),
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: () async {
                final t = _titleC.text.trim();
                final d = _descC.text.trim();
                if (t.isEmpty) return;
                final entry = Entry(
                  category: _cat,
                  title: t,
                  description: d,
                  createdAt: DateTime.now(),
                  rating: _rating.round(),
                );
                await ref.read(addEntryUcProvider).call(entry);
                ref.invalidate(entriesFutureProvider);
                if (mounted) Navigator.pop(context);
              },
            )
          ]),
        ),
      );
}
