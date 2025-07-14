import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/movie_providers.dart';

class AddMoviePage extends ConsumerStatefulWidget {
  const AddMoviePage({super.key});
  @override
  ConsumerState<AddMoviePage> createState() => _AddMoviePageState();
}

class _AddMoviePageState extends ConsumerState<AddMoviePage> {
  final _titleC = TextEditingController();
  final _yearC = TextEditingController();

  @override
  void dispose() {
    _titleC.dispose();
    _yearC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add Movie')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
                controller: _titleC,
                decoration: const InputDecoration(labelText: 'Title')),
            TextField(
                controller: _yearC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Year')),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                final title = _titleC.text.trim();
                final year = int.tryParse(_yearC.text) ?? 0;
                if (title.isEmpty || year == 0) return;
                await ref.read(addMovieUseCaseProvider).call(title, year);
                ref.invalidate(moviesFutureProvider);
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            )
          ]),
        ),
      );
}
