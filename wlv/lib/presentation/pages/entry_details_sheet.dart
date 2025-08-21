// entry_details_sheet.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:palette_generator/palette_generator.dart';

import '../providers/entry_providers.dart';
import '../../domain/entities/entry.dart';
import 'edit_entry_page.dart';

double _readBlurFromLinks(List<String> links, {double fallback = 8}) {
  for (final s in links) {
    if (s.startsWith('wlv:blur=')) {
      final v = double.tryParse(s.split('=').last);
      if (v != null) return v.clamp(0, 24);
    }
  }
  return fallback;
}

/// Darken a color by [amount] (0..1). 0.18 ≈ subtle, readable contrast.
Color _darken(Color c, [double amount = 0.18]) {
  assert(amount >= 0 && amount <= 1);
  final hsl = HSLColor.fromColor(c);
  final l = (hsl.lightness - amount).clamp(0.0, 1.0);
  return hsl.withLightness(l).toColor();
}

/// Open the details bottom sheet.
Future<void> showEntryDetailsSheet(
  BuildContext context,
  WidgetRef ref,
  Entry entry,
) async {
  await showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false, // ⬅️ turn OFF the system handle
  backgroundColor: entry.imagePaths.isNotEmpty
      ? Theme.of(context).colorScheme.surface
      : entry.effectiveColor,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
  ),
  clipBehavior: Clip.antiAlias, // ⬅️ so shape is respected
  builder: (ctx) => EntryDetailsSheet(entry: entry),
);

}

class EntryDetailsSheet extends ConsumerStatefulWidget {
  final Entry entry;
  const EntryDetailsSheet({super.key, required this.entry});
  @override
  ConsumerState<EntryDetailsSheet> createState() => _EntryDetailsSheetState();
}

class _EntryDetailsSheetState extends ConsumerState<EntryDetailsSheet> {
  late Entry _entry;

  final ScrollController _descScroll = ScrollController();

  Color _fg = Colors.white;         // default while computing
  Color _fgMuted = Colors.white70;  // derived


  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _computeTextColor();

  }


  Future<void> _computeTextColor() async {
  final String? path =
      _entry.imagePaths.isNotEmpty ? _entry.imagePaths.first : null;
  final file = (path != null) ? File(path) : null;

  final c = await textColorFromImageOrSolid(
    solidBg: _entry.effectiveColor,
    imageFile: file,
  );
  if (!mounted) return;
  setState(() {
    _fg = c;
    _fgMuted = c.withOpacity(0.78);
  });
}


  @override
  void dispose() {
    _descScroll.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _edit() async {
    final updated = await Navigator.push<Entry>(
      context,
      MaterialPageRoute(builder: (_) => EditEntryPage(entry: _entry)),
    );
    if (updated != null && mounted) {
      setState(() => _entry = updated);
      ref.invalidate(entriesFutureProvider);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text(
          'This action cannot be undone. Do you really want to delete this entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(deleteEntryUcProvider).call(_entry.id!);
      ref.read(favoritesProvider.notifier).removeIfPresent(_entry.id);
      if (mounted) {
        ref.invalidate(entriesFutureProvider);
        Navigator.pop(context);
      }
    }
  }

  Future<void> _preview() async {
    final path = _entry.imagePaths.isNotEmpty ? _entry.imagePaths.first : null;
    if (path == null) return;
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final path = _entry.imagePaths.isNotEmpty ? _entry.imagePaths.first : null;
    final blur = _readBlurFromLinks(_entry.links);

    final screen = MediaQuery.of(context).size;
    final maxSheetHeight = screen.height * 0.85;
    const maxContentWidth = 560.0;
    final maxDescHeight = screen.height * 0.40;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Material(
          color: path == null ? _entry.effectiveColor : cs.surface,
          child: Stack(
            children: [
              if (path != null && File(path).existsSync())
                Positioned.fill(
                  child: Image.file(File(path), fit: BoxFit.cover),
                ),
              
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  14, // ⬆️ add top padding above the container
                  16,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                                  padding: const EdgeInsets.only(top: 0, bottom: 20),
                                  child: Center(
                                    child: Container(
                                      width: 36,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                        // ───────── Outer SOLID darker panel for contrast ─────────
                        _OuterPanel(
                          baseColor: _entry.effectiveColor,
                          blur: blur, // blur is harmless even if panel is solid
                          child: Padding(
                            padding: const EdgeInsets.all(0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ✅ Single (internal) drag bar only
                                

                                // Title row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _entry.title,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: tt.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: _fg,
                                        ),
                                      ),
                                    ),
                                    // const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 0,
                                        vertical: 0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.secondaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: 
                                      // inside your row, where you show the rating:
_ScorePill(
  score: _entry.rating,         // 0..10
  maxScore: 10,
  size: ScorePillSize.small,   // small | medium | large
  showStar: true,
)

                                    ),
                                    // const SizedBox(width: 4),
                                    // if (path != null)
                                    //   IconButton(
                                    //     tooltip: 'Preview image',
                                    //     onPressed: _preview,
                                    //     icon: const Icon(
                                    //       Icons.zoom_out_map_rounded,
                                    //     ),
                                    //   ),
                                  ],
                                ),

                                // Category and Created
                                Padding(
                                  padding: const EdgeInsets.only(top: 6, left: 2, right: 2),
                                  child: Row(
                                    children: [
                                      Icon(Icons.category_outlined, size: 16, color: _fgMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        _entry.category.name,
                                        style: tt.bodySmall?.copyWith(color: _fgMuted),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.event_outlined, size: 16, color: _fgMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_fmtDate(_entry.createdAt)}  ${_fmtTime(_entry.createdAt)}',
                                        style: tt.bodySmall?.copyWith(color: _fgMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Description (scrollable)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Description',
                                        style: tt.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: _fg,
                                        ),
                                      ),
                                      const SizedBox(height: 0),
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: maxDescHeight,
                                        ),
                                        child: Scrollbar(
                                          controller: _descScroll,
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            controller: _descScroll,
                                            padding: const EdgeInsets.only(
                                              right: 6,
                                              top: 4,
                                              bottom: 4,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                _entry.description,
                                                style: tt.bodyLarge?.copyWith(color: _fgMuted),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Actions (Edit/Delete)
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        icon: const Icon(Icons.edit_rounded),
                                        label: const Text('Edit'),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed: _edit,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton.icon(
                                        icon: const Icon(Icons.delete_outline_rounded),
                                        label: const Text('Delete'),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          backgroundColor: cs.errorContainer,
                                          foregroundColor: cs.onErrorContainer,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed: _confirmDelete,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ───────────────────────── Small reusable bits ───────────────────────── */

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Outer **solid darker** panel that sits above the image/color background.
class _OuterPanel extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color baseColor;

  const _OuterPanel({
    required this.child,
    required this.baseColor,
    this.blur = 8,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final panelColor = _darken(baseColor, 0.18); // darker than inner cards
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: panelColor, // solid
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: child,
        ),
      ),
    );
  }
}

/// A solid (opaque) card section used for Title, Meta and Description.
class _CardSection extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blur;

  const _CardSection({
    required this.child,
    this.padding,
    this.blur = 8,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: padding ?? const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: child,
    );
  }
}

enum ScorePillSize { small, medium, large }

class _ScorePill extends StatelessWidget {
  final int score;
  final int maxScore;
  final ScorePillSize size;
  final bool showStar;

  const _ScorePill({
    required this.score,
    this.maxScore = 10,
    this.size = ScorePillSize.medium,
    this.showStar = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Sizing presets
    final double padV, padH, radius, iconSize, fontSize, borderWidth;
    switch (size) {
      case ScorePillSize.small:
        padV = 4; padH = 8; radius = 10; iconSize = 14; fontSize = 11; borderWidth = 1;
        break;
      case ScorePillSize.medium:
        padV = 6; padH = 10; radius = 12; iconSize = 16; fontSize = 13; borderWidth = 1.2;
        break;
      case ScorePillSize.large:
        padV = 8; padH = 12; radius = 14; iconSize = 18; fontSize = 15; borderWidth = 1.4;
        break;
    }

    // Clamp and map score to a color (red → amber → green)
    final s = score.clamp(0, maxScore);
    final t = maxScore == 0 ? 0.0 : s / maxScore;
    final Color low   = const Color(0xFFEF5350); // red
    final Color mid   = const Color.fromARGB(255, 189, 145, 11); // amber
    final Color high  = const Color.fromARGB(255, 255, 191, 1); // green
    final Color gradStart = t < 0.5
        ? Color.lerp(low,  mid, t / 0.5)!
        : Color.lerp(mid, high, (t - 0.5) / 0.5)!;

    // Slightly darker end for subtle depth
    final HSLColor hsl = HSLColor.fromColor(gradStart);
    final Color gradEnd = hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0)).toColor();

    // Choose readable text color (on dark-ish gradient use white)
    final Color textColor = Colors.white;

    return Semantics(
      label: 'Rating $s out of $maxScore',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradStart, gradEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: gradStart.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showStar) ...[
                Icon(Icons.star_rounded, size: iconSize, color: textColor),
                const SizedBox(width: 6),
              ],
              // Score text with tiny fraction suppressed
              Text(
                '$s / $maxScore',
                style: tt.labelLarge?.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




/// Returns a high-contrast text color (black/white) based on an image's
/// dominant color. If the image doesn't exist, falls back to [solidBg].
Future<Color> textColorFromImageOrSolid({
  required Color solidBg,
  File? imageFile,
  double luminanceThreshold = 0.53, // higher → more likely black text
}) async {
  Color base = solidBg;

  if (imageFile != null && await imageFile.exists()) {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        FileImage(imageFile),
        size: const Size(200, 120), // small sample for speed
        maximumColorCount: 12,
      );
      base = palette.dominantColor?.color ?? base;
    } catch (_) {
      // swallow and use fallback solid color
    }
  }

  // Choose black/white for maximum contrast
  return base.computeLuminance() > luminanceThreshold
      ? Colors.black
      : Colors.white;
}