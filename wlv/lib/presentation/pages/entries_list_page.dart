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
    final async = ref.watch(entriesFilteredProvider);
    final query = ref.watch(entriesFilterProvider).query.trim();

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (entries) => entries.isEmpty
          ? const Center(child: Text('No entries match your filters'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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

    final String? imgPath =
        (entry.imagePaths.isNotEmpty && entry.imagePaths.first.trim().isNotEmpty)
            ? entry.imagePaths.first
            : null;

    final blur = _readBlurFromLinks(entry.links);
    final radius = BorderRadius.circular(16);

    return Card(
  margin: const EdgeInsets.symmetric(vertical: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: cs.outlineVariant),
  ),
  color: entry.effectiveColor, // always use picked color
  elevation: 0,
  clipBehavior: Clip.antiAlias,
  child: InkWell(
    onTap: onTap,
    child: Builder(
      builder: (context) {
        final hasImage = imgPath != null && File(imgPath!).existsSync();
        const r = 16.0; // base corner radius

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: square bottom if there is an image ────────────────
            _HeaderGroup(
              squaredBottom: hasImage,
              radius: r,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CircleAvatar(
                  //   backgroundColor: cs.secondaryContainer,
                  //   foregroundColor: cs.onSecondaryContainer,
                  //   child: Text(entry.category.name.characters.first.toUpperCase()),
                  // ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _highlightText(
                          entry.title,
                          query,
                          tt.titleLarge!.copyWith(fontWeight: FontWeight.w700),
                          cs,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 0,
                          runSpacing: 0,
                          children: List.generate(
                            entry.rating.clamp(0, 10),
                            (i) => Icon(
                              Icons.star_rounded,
                              size: MediaQuery.of(context).size.width < 360
                                  ? 16
                                  : (MediaQuery.of(context).size.width < 400 ? 18 : 11),
                              color: _colorForIndex(i, 10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _shortDate(entry.createdAt),
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                          tooltip: isFav ? 'Unfavorite' : 'Favorite',
                          onPressed: () => ref.read(favoritesProvider.notifier).toggle(entry.id),
                          icon: Icon(
                            isFav ? Icons.star_rounded : Icons.star_border_rounded,
                            color: isFav ? Colors.amber : cs.onSurfaceVariant,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 0),
                        // const Icon(Icons.chevron_right),
                        Text(entry.category.name),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Image: only round the *bottom* corners so it mates the header ──
            if (hasImage) ...[
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(r),
                  bottomRight: Radius.circular(r),
                ),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.file(
                        File(imgPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    Positioned(
                      top: 22,
                      right: 22,
                      child: Material(
                        color: cs.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(7),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _openPreview(context, imgPath!),
                          child: const Padding(
                            padding: EdgeInsets.all(1.3),
                            child: Icon(Icons.zoom_out_map_rounded, size: 24),
                          ),
                        ),
                      ),
                    ),
                    // optional subtle gradient to blend with card bg
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 18,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                entry.effectiveColor.withOpacity(0.85),
                                entry.effectiveColor.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    ),
  ),
);
  }

  

  static Future<void> _openPreview(BuildContext context, String path) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Preview',
      pageBuilder: (_, __, ___) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(color: Colors.black.withOpacity(0.35)),
                ),
              ),
              Center(
                child: Hero(
                  tag: path,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(File(path), fit: BoxFit.contain),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

/* ───────────────────────── helpers ───────────────────────── */

class _HeaderGroup extends StatelessWidget {
  final Widget child;
  final bool squaredBottom;
  final double radius;

  const _HeaderGroup({
    required this.child,
    this.squaredBottom = false,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final BorderRadius br = squaredBottom
        ? BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          )
        : BorderRadius.all(Radius.circular(radius));

    return Container(
      decoration: BoxDecoration(
        color: cs.surface, // solid, contrasted surface for readability
        borderRadius: br,
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: child,
    );
  }
}
