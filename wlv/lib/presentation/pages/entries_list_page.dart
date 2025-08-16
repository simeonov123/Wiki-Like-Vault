import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/entry_providers.dart';
import '../../domain/entities/entry.dart';
import 'entry_details_sheet.dart';

/* read blur from links meta */
double _readBlurFromLinks(List<String> links, {double fallback = 8}) {
  for (final s in links) {
    if (s.startsWith('wlv:blur=')) {
      final v = double.tryParse(s.split('=').last);
      if (v != null) return v.clamp(0, 24);
    }
  }
  return fallback;
}

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

    final String? bgPath =
        (entry.imagePaths.isNotEmpty && entry.imagePaths.first.trim().isNotEmpty)
            ? entry.imagePaths.first
            : null;
    final blur = _readBlurFromLinks(entry.links);

    final borderRadius = BorderRadius.circular(14);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: cs.outlineVariant),
      ),
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            if (bgPath != null && File(bgPath).existsSync())
              Positioned.fill(
                child: Image.file(
                  File(bgPath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            // Frosted content panel so image stays fully visible
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: _Frosted(
                blur: blur,
                radius: BorderRadius.circular(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: CircleAvatar(
                        backgroundColor: cs.secondaryContainer,
                        foregroundColor: cs.onSecondaryContainer,
                        child: Text(
                          entry.category.name.characters.first.toUpperCase(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Textual content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _highlightText(
                            entry.title,
                            query,
                            tt.titleMedium!,
                            cs,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 6),
                          // Stars wrap if they must to avoid row overflow on small widths
                          Wrap(
                            spacing: 3,
                            runSpacing: 0,
                            children: List.generate(
                              entry.rating.clamp(0, 10),
                              (i) => Icon(
                                Icons.star_rounded,
                                size: MediaQuery.of(context).size.width < 360
                                    ? 16
                                    : (MediaQuery.of(context).size.width < 400
                                        ? 18
                                        : 20),
                                color: _colorForIndex(i, 10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _highlightText(
                            '★ ${entry.rating} — ${entry.description.trim()}',
                            query,
                            tt.bodyMedium!,
                            cs,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _shortDate(entry.createdAt),
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Trailing actions — fixed width so they never overflow
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints:
                                const BoxConstraints.tightFor(width: 44, height: 44),
                            tooltip: isFav ? 'Unfavorite' : 'Favorite',
                            onPressed: () => ref
                                .read(favoritesProvider.notifier)
                                .toggle(entry.id),
                            icon: Icon(
                              isFav
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: isFav ? Colors.amber : cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _colorForIndex(int index, int count) {
    final t = count <= 1 ? 1.0 : index / (count - 1);
    if (t <= 0.5) {
      return Color.lerp(Colors.red, Colors.teal, t / 0.5)!;
    } else {
      return Color.lerp(Colors.teal, Colors.yellow, (t - 0.5) / 0.5)!;
    }
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

/* local frosted helper */
class _Frosted extends StatelessWidget {
  final double blur;
  final BorderRadiusGeometry radius;
  final Widget child;

  const _Frosted({
    required this.child,
    this.blur = 8,
    this.radius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.70),
            borderRadius: radius,
            border: Border.all(color: cs.outlineVariant),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: child,
        ),
      ),
    );
  }
}
