import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/entry.dart';
import '../providers/entry_providers.dart';

/* reuse the blur helpers from Add page */
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

class EditEntryPage extends ConsumerStatefulWidget {
  final Entry entry;
  const EditEntryPage({super.key, required this.entry});

  @override
  ConsumerState<EditEntryPage> createState() => _EditEntryPageState();
}

class _EditEntryPageState extends ConsumerState<EditEntryPage> {
  late final TextEditingController _titleC;
  late final TextEditingController _descC;
  late double _rating;
  late Category _cat;

  String? _cardBgPath; // first imagePaths item
  late double _blur;
  Color? _bgColor; // solid background color when no image

  late final Entry _initial;

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h'; // add alpha if missing
    return Color(int.parse(h, radix: 16));
  }

  /// Convert a nullable Color to nullable hex (AARRGGBB with '#')
  String? _hexOrNull(Color? c) =>
      c == null ? null : Entry.colorToHex(c);

  @override
  void initState() {
    super.initState();
    _initial = widget.entry;
    _titleC = TextEditingController(text: _initial.title);
    _descC = TextEditingController(text: _initial.description);
    _rating = _initial.rating.toDouble();
    _cat = _initial.category;
    _cardBgPath =
        _initial.imagePaths.isNotEmpty ? _initial.imagePaths.first : null;
    _blur = _readBlurFromLinks(_initial.links);

    // Prefer an explicit color; otherwise hydrate from persisted hex.
    _bgColor = _initial.bgColor ?? _parseHex(_initial.bgColorHex);
  }

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final titleChanged = _titleC.text.trim() != _initial.title;
    final descChanged = _descC.text.trim() != _initial.description;
    final ratingChanged = _rating.round() != _initial.rating;
    final catChanged = _cat != _initial.category;
    final imageChanged =
        (_initial.imagePaths.isNotEmpty ? _initial.imagePaths.first : null) !=
            _cardBgPath;
    final blurChanged =
        _readBlurFromLinks(_initial.links) != _blur;

    // Compare color by HEX so it works regardless of how initial was provided
    final String? initialHex = _initial.bgColorHex ??
        (_initial.bgColor == null ? null : Entry.colorToHex(_initial.bgColor!));
    final String? currentHex = _hexOrNull(_bgColor);
    final colorChanged = initialHex != currentHex;

    return titleChanged ||
        descChanged ||
        ratingChanged ||
        catChanged ||
        imageChanged ||
        blurChanged ||
        colorChanged;
  }

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

  Future<void> _pickCardBg() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _cardBgPath = x.path);
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
        return Stack(
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
        );
      },
    );
  }

  Future<void> _pickBgColor() async {
    Color temp = _bgColor ?? Theme.of(context).colorScheme.surface;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick background color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
            enableAlpha: true,
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithHue,
            pickerAreaHeightPercent: 0.85,
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
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? scheme.secondaryContainer : scheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? scheme.secondary : scheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cat.name,
                                style: Theme.of(c).textTheme.titleMedium?.copyWith(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? scheme.onSecondaryContainer
                                      : scheme.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_rounded, color: scheme.secondary),
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

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasChanges) return true;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Discard and go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    double descTargetHeight(BuildContext ctx) {
      final h = MediaQuery.of(ctx).size.height;
      return (h * 0.35).clamp(180.0, 420.0);
    }

    final radius = BorderRadius.circular(18);

    return WillPopScope(
      onWillPop: _confirmDiscardIfNeeded,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // dismiss keyboard
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Edit Entry'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                if (await _confirmDiscardIfNeeded()) {
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
            actions: [
              IconButton(
                tooltip: 'Pick background color',
                icon: const Icon(Icons.color_lens_outlined),
                onPressed: _pickBgColor,
              ),
              IconButton(
                tooltip: 'Clear color',
                icon: const Icon(Icons.format_color_reset_rounded),
                onPressed: _bgColor == null ? null : _clearBgColor,
              ),
            ],
          ),

          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final t = _titleC.text.trim();
                    final d = _descC.text.trim();
                    if (t.isEmpty) return;

                    final updated = _initial.copyWith(
                      category: _cat,
                      title: t,
                      description: d,
                      rating: _rating.round(),
                      imagePaths: _cardBgPath == null ? const [] : <String>[_cardBgPath!],
                      links: _writeBlurToLinks(_initial.links, _blur),
                      bgColor: _bgColor,                              // for immediate UI
                      bgColorHex: _hexOrNull(_bgColor),               // ← PERSIST THIS
                    );

                    await ref.read(updateEntryUcProvider).call(updated);
                    ref.invalidate(entriesFutureProvider);
                    if (mounted) Navigator.pop<Entry>(context, updated);
                  },
                ),
              ),
            ),
          ),

          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // ── Background controls (grouped) ────────────────────────────
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
                      Text('Card Background',
                          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
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
                                style: tt.labelLarge?.copyWith(color: cs.onSecondaryContainer)),
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

                // ── Details fields on frosted panel over bg ──────────────────
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

                // ── Rating ───────────────────────────────────────────────────
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
                              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_rating.round()} / 10',
                              style: tt.labelLarge?.copyWith(color: cs.onSecondaryContainer),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          const count = 10;
                          const itemPadding = 3.0;
                          const totalPadding = count * (2 * itemPadding);
                          final maxWidth = constraints.maxWidth;
                          final available = (maxWidth - totalPadding).clamp(60.0, 4000.0);
                          final itemSize = (available / count).clamp(18.0, 48.0).toDouble();

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(count, (i) {
                              final filled = (i + 1) <= _rating;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                child: GestureDetector(
                                  onHorizontalDragUpdate: (d) {
                                    final box = context.findRenderObject() as RenderBox?;
                                    if (box == null) return;
                                    final pos = box.globalToLocal(d.globalPosition);
                                    final relative = (pos.dx / maxWidth).clamp(0.0, 1.0);
                                    final newRating =
                                        (relative * count).clamp(1, count.toDouble());
                                    setState(() => _rating = newRating.roundToDouble());
                                  },
                                  onTap: () => setState(() => _rating = (i + 1).toDouble()),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: itemSize,
                                    color: filled
                                        ? _colorForIndex(i, count)
                                        : Theme.of(context)
                                            .colorScheme
                                            .outlineVariant
                                            .withOpacity(0.35),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* same frosted helper */
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
