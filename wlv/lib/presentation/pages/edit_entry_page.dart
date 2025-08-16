import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/entry.dart';
import '../providers/entry_providers.dart';

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

  late final Entry _initial;

  @override
  void initState() {
    super.initState();
    _initial = widget.entry;
    _titleC = TextEditingController(text: _initial.title);
    _descC = TextEditingController(text: _initial.description);
    _rating = _initial.rating.toDouble();
    _cat = _initial.category;
  }

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _titleC.text.trim() != _initial.title ||
      _descC.text.trim() != _initial.description ||
      _rating.round() != _initial.rating ||
      _cat != _initial.category;

  Color _colorForIndex(int index, int count) {
    final t = count <= 1 ? 1.0 : index / (count - 1);
    if (t <= 0.5) {
      return Color.lerp(Colors.red, Colors.teal, t / 0.5)!;
    } else {
      return Color.lerp(Colors.teal, Colors.yellow, (t - 0.5) / 0.5)!;
    }
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

    double _descTargetHeight(BuildContext ctx) {
      final h = MediaQuery.of(ctx).size.height;
      return (h * 0.35).clamp(180.0, 420.0);
    }

    return WillPopScope(
      onWillPop: _confirmDiscardIfNeeded,
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
              _SectionCard(
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

                    // Description — large, fills area, scrolls inside
                    SizedBox(
                      height: _descTargetHeight(context),
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

              const SizedBox(height: 22),

              _SectionCard(
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
                            style: tt.labelLarge?.copyWith(
                              color: cs.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Responsive manual star row (drag/tap)
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        const count = 10;
                        const itemPadding = 3.0;
                        final totalPadding = count * (2 * itemPadding);
                        final maxWidth = constraints.maxWidth;
                        final available = (maxWidth - totalPadding).clamp(60.0, 4000.0);
                        final itemSize =
                            (available / count).clamp(18.0, 48.0).toDouble();

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(count, (i) {
                            final filled = (i + 1) <= _rating;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3.0),
                              child: GestureDetector(
                                onHorizontalDragUpdate: (d) {
                                  final box =
                                      context.findRenderObject() as RenderBox?;
                                  if (box == null) return;
                                  final pos =
                                      box.globalToLocal(d.globalPosition);
                                  final relative =
                                      (pos.dx / maxWidth).clamp(0.0, 1.0);
                                  final newRating = (relative * count)
                                      .clamp(1, count.toDouble());
                                  setState(() =>
                                      _rating = newRating.roundToDouble());
                                },
                                onTap: () =>
                                    setState(() => _rating = (i + 1).toDouble()),
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
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: child,
    );
  }
}
