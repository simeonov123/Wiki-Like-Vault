import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/entry_providers.dart';
import '../../domain/entities/entry.dart';
import 'entry_details_sheet.dart';

class EntriesListBody extends ConsumerWidget {
  const EntriesListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(entriesFilteredProvider); // ← no pagination
    final query = ref.watch(entriesFilterProvider).query.trim();

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (entries) => entries.isEmpty
          ? const Center(child: Text('No entries match your filters'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final e = entries[i];
                return _EntryCard(
                  entry: e,
                  query: query,
                  onTap: () => showEntryDetailsSheet(context, ref, e),
                );
              },
            ),
    );
  }
}

/* ───────────────────────────── Card ───────────────────────────── */

class _EntryCard extends ConsumerWidget {
  final Entry entry;
  final String query;
  final VoidCallback onTap;

  const _EntryCard({
    required this.entry,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final favs = ref.watch(favoritesProvider);
    final isFav = favs.contains(entry.id);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      color: cs.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: cs.secondaryContainer,
                foregroundColor: cs.onSecondaryContainer,
                child: Text(entry.category.name.characters.first.toUpperCase()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _highlightText(entry.title, query, tt.titleMedium!, cs,
                        maxLines: 1),
                    const SizedBox(height: 6),
                    _StarsRow(rating: entry.rating, maxCount: 10),
                    const SizedBox(height: 8),
                    _highlightText(
                      '★ ${entry.rating} — ${entry.description.trim()}',
                      query,
                      tt.bodyMedium!,
                      cs,
                      maxLines: 4, // up to 4 lines, auto height if less
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _shortDate(entry.createdAt),
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: isFav ? 'Unfavorite' : 'Favorite',
                    onPressed: () =>
                        ref.read(favoritesProvider.notifier).toggle(entry.id),
                    icon: Icon(
                      isFav
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: isFav ? Colors.amber : cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Text _highlightText(
    String text,
    String query,
    TextStyle base,
    ColorScheme cs, {
    int? maxLines,
  }) {
    if (query.isEmpty) {
      return Text(text,
          style: base, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start), style: base));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: base));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: base.copyWith(
          backgroundColor: cs.tertiaryContainer.withOpacity(0.7),
          color: cs.onTertiaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ));
      start = idx + q.length;
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  static String _shortDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/* ───────────────────── Stars (gradient, N of rating) ───────────────────── */

class _StarsRow extends StatelessWidget {
  final int rating; // 1..10
  final int maxCount;

  const _StarsRow({required this.rating, required this.maxCount});

  Color _colorForIndex(int index, int count) {
    final t = count <= 1 ? 1.0 : index / (count - 1);
    if (t <= 0.5) {
      return Color.lerp(Colors.red, Colors.teal, t / 0.5)!;
    } else {
      return Color.lerp(Colors.teal, Colors.yellow, (t - 0.5) / 0.5)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = rating.clamp(0, maxCount);
    final width = MediaQuery.of(context).size.width;
    final starSize = width < 360 ? 16.0 : (width < 400 ? 18.0 : 20.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Icon(Icons.star_rounded,
              size: starSize, color: _colorForIndex(i, maxCount)),
        );
      }),
    );
  }
}
