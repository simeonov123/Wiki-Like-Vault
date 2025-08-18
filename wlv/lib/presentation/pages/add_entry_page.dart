import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/entry.dart';
import '../providers/entry_providers.dart';

/* ───────────── helpers to persist per-entry blur/color without DB changes ───────────── */
double _readBlurFromLinks(List<String> links, {double fallback = 8}) {
  for (final s in links) {
    if (s.startsWith('wlv:blur=')) {
      final v = double.tryParse(s.split('=').last);
      if (v != null) return v.clamp(0, 24);
    }
  }
  return fallback;
}

List<String> _writeBlurToLinks(List<String> old, double blur) {
  final kept = old.where((s) => !s.startsWith('wlv:blur=')).toList();
  return ['wlv:blur=${blur.toStringAsFixed(2)}', ...kept];
}

Color? _readBgColorFromLinks(List<String> links) {
  for (final s in links) {
    if (s.startsWith('wlv:bg=')) {
      final v = s.split('=').last.trim();
      // supports hex like #FFAABBCC or 0xFFAABBCC
      try {
        String hex = v;
        if (hex.startsWith('#')) hex = '0x${hex.substring(1)}';
        final val = int.parse(hex);
        return Color(val);
      } catch (_) {}
    }
  }
  return null;
}

List<String> _writeColorToLinks(List<String> old, Color? c) {
  // remove previous
  final kept = old.where((s) => !s.startsWith('wlv:bg=')).toList();
  if (c == null) return kept;
  final hex = c.value.toRadixString(16).padLeft(8, '0').toUpperCase(); // AARRGGBB
  return ['wlv:bg=#$hex', ...kept];
}
/* ─────────────────────────────────────────────────────────────────────────────── */

class AddEntryPage extends ConsumerStatefulWidget {
  const AddEntryPage({super.key});
  @override
  ConsumerState<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends ConsumerState<AddEntryPage> {
  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  double _rating = 5; // 1..10
  Category _cat = Category.book;

  String? _cardBgPath; // persisted copy path inside app docs
  double _blur = 8;    // 0..24 visual blur (preview/list/details)
  Color? _bgColor;     // optional solid bg color when no image

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    super.dispose();
  }

  // Negative (red) → Neutral (teal) → Positive (yellow)
  Color _colorForIndex(int index, int count) {
    final t = count <= 1 ? 1.0 : index / (count - 1);
    if (t <= 0.5) return Color.lerp(Colors.red, Colors.teal, t / 0.5)!;
    return Color.lerp(Colors.teal, Colors.yellow, (t - 0.5) / 0.5)!;
  }

  InputDecoration _dec(
    String label, {
    String? hint,
    IconData? icon,
    VoidCallback? onIconTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final iconButton = icon == null
        ? null
        : InkWell(
            onTap: onIconTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(icon, color: scheme.onSurfaceVariant),
            ),
          );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: scheme.surface.withOpacity(0.9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: iconButton,
    );
  }

  /// Pick an image and **copy it into the app documents directory** so the path remains valid after restarts.
  Future<void> _pickCardBg() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      await Directory(docsDir.path).create(recursive: true);
      final ext = p.extension(x.path).isEmpty ? '.jpg' : p.extension(x.path);
      final fileName =
          'entry_${DateTime.now().millisecondsSinceEpoch}${ext.toLowerCase()}';
      final destPath = p.join(docsDir.path, fileName);
      final copied = await File(x.path).copy(destPath);
      setState(() => _cardBgPath = copied.path);
    } catch (_) {
      // fallback to temp path if copy fails (still lets user proceed)
      setState(() => _cardBgPath = x.path);
    }
  }

  void _clearCardBg() => setState(() => _cardBgPath = null);

  Future<void> _previewCardBg() async {
    if (_cardBgPath == null) return;
    final path = _cardBgPath!;
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Preview',
      pageBuilder: (_, __, ___) {
        return GestureDetector(
          onTap: () => Navigator.pop(context), // tap outside to dismiss
          child: Stack(
            children: [
              // blur the whole backdrop
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
                    child: Image.file(
                      File(path),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCategoryPicker() async {
    final selected = await showModalBottomSheet<Category>(
      context: context,
      useSafeArea: true,
      isScrollControlled: false,
      showDragHandle: true,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        const items = Category.values;
        return Material(
          color: Theme.of(ctx).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose category',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                fit: FlexFit.loose,
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (c, i) {
                    final cat = items[i];
                    final isSelected = cat == _cat;
                    final scheme = Theme.of(c).colorScheme;

                    return InkWell(
                      onTap: () => Navigator.of(ctx).pop(cat),
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? scheme.secondaryContainer
                              : scheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? scheme.secondary
                                : scheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cat.name,
                                style: Theme.of(c).textTheme.titleMedium?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? scheme.onSecondaryContainer
                                          : scheme.onSurface,
                                    ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_rounded,
                                  color: scheme.secondary),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemCount: items.length,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != _cat) {
      setState(() => _cat = selected);
    }
  }

    Future<void> _pickBgColor() async {
    Color temp = _bgColor ?? Theme.of(context).colorScheme.surface;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick background color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // FULL spectrum wheel
              ColorPicker(
                pickerColor: temp,
                onColorChanged: (c) => temp = c,
                enableAlpha: true,
                displayThumbColor: true,
                pickerAreaHeightPercent: 0.85,
                paletteType: PaletteType.hsvWithHue,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _bgColor = temp);
              Navigator.pop(ctx);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }


  void _clearBgColor() => setState(() => _bgColor = null);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // adaptive target height for description editor
    double descTargetHeight(BuildContext ctx) {
      final h = MediaQuery.of(ctx).size.height;
      return (h * 0.35).clamp(180.0, 420.0);
    }

    final radius = BorderRadius.circular(18);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // dismiss keyboard
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Entry'),
          centerTitle: true,
        ),

        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              height: 54,
              child: FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Entry'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final t = _titleC.text.trim();
                  final d = _descC.text.trim();
                  if (t.isEmpty) return;

                  // persist visual settings in links
                  List<String> links = _writeBlurToLinks(const [], _blur);
                  links = _writeColorToLinks(links, _bgColor);

                  final entry = Entry(
  category: _cat,
  title: t,
  description: d,
  imagePaths: _cardBgPath == null ? const [] : <String>[_cardBgPath!],
  links: links, // keep if you still want blur meta in links
  createdAt: DateTime.now(),
  rating: _rating.round(),
  bgColor: _bgColor, // optional (used immediately in UI)
  bgColorHex: _bgColor == null ? null : Entry.colorToHex(_bgColor!),
);

                  await ref.read(addEntryUcProvider).call(entry);
                  ref.invalidate(entriesFutureProvider);
                  if (mounted) Navigator.pop(context);
                },
              ),
            ),
          ),
        ),

        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // ── Background controls (image) ───────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: radius,
                  border: Border.all(color: cs.outlineVariant),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Card Background Image',
                        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    // Use Wrap to avoid Row overflows on tiny widths
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _pickCardBg,
                          icon: const Icon(Icons.image_rounded),
                          label: const Text('Choose'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _cardBgPath == null ? null : _previewCardBg,
                          icon: const Icon(Icons.zoom_out_map_rounded),
                          label: const Text('Preview'),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Clear',
                          onPressed: _cardBgPath == null ? null : _clearCardBg,
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('Blur ${_blur.toStringAsFixed(0)}',
                              style: tt.labelLarge?.copyWith(
                                  color: cs.onSecondaryContainer)),
                        ),
                      ],
                    ),
                    if (_cardBgPath != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_cardBgPath!),
                          fit: BoxFit.cover,
                          height: 140,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            height: 140,
                            alignment: Alignment.center,
                            child: const Text('Could not load image'),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Slider(
                      value: _blur,
                      min: 0,
                      max: 24,
                      divisions: 24,
                      label: '${_blur.round()}',
                      onChanged: (v) => setState(() => _blur = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Background Color (HSV wheel) ─────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: radius,
                  border: Border.all(color: cs.outlineVariant),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Background Color',
                        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickBgColor,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: _bgColor ?? cs.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _bgColor == null ? 'Pick color' : '#${(_bgColor!.value.toRadixString(16)).padLeft(8, '0').toUpperCase()}',
                                style: tt.labelLarge?.copyWith(
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Clear color',
                          onPressed: _bgColor == null ? null : _clearBgColor,
                          icon: const Icon(Icons.format_color_reset_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Used when no image is set. Saved in links meta (no DB change).',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Details section with frosted fields over the selected bg ────
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: radius,
                  border: Border.all(color: cs.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withOpacity(0.06),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (_cardBgPath != null && File(_cardBgPath!).existsSync())
                      Positioned.fill(
                        child: Image.file(File(_cardBgPath!), fit: BoxFit.cover),
                      )
                    else
                      Positioned.fill(
                        child: Container(color: _bgColor ?? cs.surface),
                      ),
                    // NO dimming — keep image/color fully visible
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      child: _Frosted(
                        blur: _blur,
                        child: Column(
                          children: [
                            TextFormField(
                              readOnly: true,
                              onTap: _showCategoryPicker,
                              decoration: _dec(
                                'Category',
                                hint: _cat.name,
                                icon: Icons.category_outlined,
                                onIconTap: _showCategoryPicker,
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _titleC,
                              decoration: _dec(
                                'Title',
                                hint: 'e.g., The Pragmatic Programmer',
                                icon: Icons.title_outlined,
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              height: descTargetHeight(context),
                              child: TextField(
                                controller: _descC,
                                expands: true,
                                maxLines: null,
                                minLines: null,
                                keyboardType: TextInputType.multiline,
                                textAlignVertical: TextAlignVertical.top,
                                decoration: _dec(
                                  'Description',
                                  hint: 'Optional notes, thoughts, highlights…',
                                  icon: Icons.notes_outlined,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Rating section (unchanged visually) ────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: radius,
                  border: Border.all(color: cs.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withOpacity(0.06),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rating',
                            style: tt.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_rating.round()} / 10',
                            style: tt.labelLarge
                                ?.copyWith(color: cs.onSecondaryContainer),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ResponsiveRatingBar(
                      itemCount: 10,
                      rating: _rating,
                      unratedColor: cs.outlineVariant.withOpacity(0.35),
                      colorForIndex: (i, count) => _colorForIndex(i, count),
                      onChanged: (val) =>
                          setState(() => _rating = val.roundToDouble()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsiveRatingBar extends StatelessWidget {
  final int itemCount;
  final double rating;
  final double minRating;
  final bool allowHalf;
  final double horizontalItemPadding;
  final Color? unratedColor;
  final Color Function(int index, int count) colorForIndex;
  final ValueChanged<double> onChanged;

  const _ResponsiveRatingBar({
    required this.itemCount,
    required this.rating,
    required this.colorForIndex,
    required this.onChanged,
    this.unratedColor,
    this.minRating = 1,
    this.allowHalf = false,
    this.horizontalItemPadding = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final totalPadding = itemCount * (2 * horizontalItemPadding);
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(ctx).size.width;
        final available = (maxWidth - totalPadding).clamp(60.0, 4000.0);
        final itemSize = (available / itemCount).clamp(18.0, 48.0);

        return RatingBar.builder(
          initialRating: rating.clamp(minRating, itemCount.toDouble()),
          minRating: minRating,
          itemCount: itemCount,
          itemSize: itemSize,
          allowHalfRating: allowHalf,
          updateOnDrag: true,
          unratedColor: unratedColor,
          itemPadding:
              EdgeInsets.symmetric(horizontal: horizontalItemPadding),
          itemBuilder: (context, index) => Icon(
            Icons.star_rounded,
            color: colorForIndex(index, itemCount),
          ),
          onRatingUpdate: onChanged,
        );
      },
    );
  }
}

/* ─────────────────────── Frosted glass helper ─────────────────────── */
class _Frosted extends StatelessWidget {
  final double blur;
  final BorderRadiusGeometry radius;
  final Widget child;

  const _Frosted({
    required this.child,
    this.blur = 8,
    this.radius = const BorderRadius.all(Radius.circular(18)),
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
