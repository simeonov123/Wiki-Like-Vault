import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/movie_providers.dart';

/// Body-only widget; no Scaffold.
class MoviesListBody extends ConsumerWidget {
  const MoviesListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(moviesFutureProvider);

    return moviesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (movies) => movies.isEmpty
          ? const Center(child: Text('No movies yet'))
          : ListView.builder(
              itemCount: movies.length,
              itemBuilder: (_, i) {
                final m = movies[i];
                return ListTile(
                  title: Text(m.title),
                  subtitle: Text(m.year.toString()),
                );
              },
            ),
    );
  }
}
