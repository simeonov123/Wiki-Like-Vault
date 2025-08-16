import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/entry.dart';
import '../providers/entry_providers.dart';

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

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    super.dispose();
  }

  // Negative (red) → Neutral (teal) → Positive (yellow)
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
                                      fontWeight:
                                          isSelected ? FontWeight.w700 : FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // adaptive target height for description editor
    double _descTargetHeight(BuildContext ctx) {
      final h = MediaQuery.of(ctx).size.height;
      return (h * 0.35).clamp(180.0, 420.0);
    }

    return Scaffold(
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

                final entry = Entry(
                  category: _cat,
                  title: t,
                  description: d,
                  createdAt: DateTime.now(),
                  rating: _rating.round(),
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
            // Section: Details
            Container(
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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

            // Section: Rating
            Container(
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rating',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
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
    this.minRating = 1.0,
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
