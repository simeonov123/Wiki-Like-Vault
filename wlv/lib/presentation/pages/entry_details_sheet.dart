// entry_details_sheet.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
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
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.secondaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_entry.rating} / 10',
                                        style: tt.labelLarge?.copyWith(
                                          color: cs.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (path != null)
                                      IconButton(
                                        tooltip: 'Preview image',
                                        onPressed: _preview,
                                        icon: const Icon(
                                          Icons.zoom_out_map_rounded,
                                        ),
                                      ),
                                  ],
                                ),

                                // Category and Created
                                Padding(
                                  padding: const EdgeInsets.only(top: 6, left: 2, right: 2),
                                  child: Row(
                                    children: [
                                      Icon(Icons.category_outlined, size: 16, color: cs.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        _entry.category.name,
                                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.event_outlined, size: 16, color: cs.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_fmtDate(_entry.createdAt)}  ${_fmtTime(_entry.createdAt)}',
                                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
                                                style: tt.bodyLarge,
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
