import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category.dart';
import '../providers/entry_providers.dart';

/// Opens the filter panel as a modal bottom sheet (slides up).
Future<void> showEntriesFilterSheet({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  final filter = ref.read(entriesFilterProvider);

  final queryController = TextEditingController(text: filter.query);
  Set<Category> tempCats = {...filter.categories};
  EntrySortBy tempSort   = filter.sortBy;
  bool tempAscending     = filter.ascending;
  DateTime? tempFrom     = filter.from;
  DateTime? tempTo       = filter.to;
  bool tempFavoritesOnly = filter.favoritesOnly;

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    barrierColor: Colors.black.withOpacity(0.35),
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: _FilterSheetContent(
          queryController: queryController,
          tempCats: tempCats,
          tempSort: tempSort,
          tempAscending: tempAscending,
          tempFrom: tempFrom,
          tempTo: tempTo,
          tempFavoritesOnly: tempFavoritesOnly,
          onApply: (q, cats, sort, asc, from, to, favOnly) {
            final n = ref.read(entriesFilterProvider.notifier);
            n
              ..setQuery(q)
              ..setCategories(cats)
              ..setSort(sort)
              ..setDateRange(from: from, to: to)
              ..setFavoritesOnly(favOnly);
            if (sort != EntrySortBy.category) {
              final currentAscending = ref.read(entriesFilterProvider).ascending;
              if (currentAscending != asc) n.toggleAscending();
            }
            Navigator.pop(ctx);
          },
          onClear: () {
            ref.read(entriesFilterProvider.notifier).clear();
            Navigator.pop(ctx);
          },
        ),
      );
    },
  );
}

class _FilterSheetContent extends StatefulWidget {
  final TextEditingController queryController;
  final Set<Category> tempCats;
  final EntrySortBy tempSort;
  final bool tempAscending;
  final DateTime? tempFrom;
  final DateTime? tempTo;
  final bool tempFavoritesOnly;
  final void Function(
    String query,
    Set<Category> cats,
    EntrySortBy sort,
    bool ascending,
    DateTime? from,
    DateTime? to,
    bool favoritesOnly,
  ) onApply;
  final VoidCallback onClear;

  const _FilterSheetContent({
    required this.queryController,
    required this.tempCats,
    required this.tempSort,
    required this.tempAscending,
    required this.tempFrom,
    required this.tempTo,
    required this.tempFavoritesOnly,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  late Set<Category> _cats;
  late EntrySortBy _sort;
  late bool _ascending;
  DateTime? _from;
  DateTime? _to;
  late bool _favoritesOnly;

  @override
  void initState() {
    super.initState();
    _cats = {...widget.tempCats};
    _sort = widget.tempSort;
    _ascending = widget.tempAscending;
    _from = widget.tempFrom;
    _to = widget.tempTo;
    _favoritesOnly = widget.tempFavoritesOnly;
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial = DateTimeRange(
      start: _from ?? now.subtract(const Duration(days: 30)),
      end: _to ?? now,
    );
    final res = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initial,
      helpText: 'Filter by date range',
    );
    if (res != null) {
      setState(() {
        _from = DateTime(res.start.year, res.start.month, res.start.day);
        _to   = DateTime(res.end.year,   res.end.month,   res.end.day);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Text('Filter & Sort',
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  tooltip: 'Clear all',
                  onPressed: widget.onClear,
                  icon: const Icon(Icons.clear_all),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search
                  TextField(
                    controller: widget.queryController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search title or description…',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withOpacity(0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onSubmitted: (_) => widget.onApply(
                      widget.queryController.text, _cats, _sort, _ascending, _from, _to, _favoritesOnly),
                  ),

                  const SizedBox(height: 16),

                  // Favorites only
                  Row(
                    children: [
                      Switch.adaptive(
                        value: _favoritesOnly,
                        onChanged: (v) => setState(() => _favoritesOnly = v),
                      ),
                      const SizedBox(width: 8),
                      Text('Favorites only', style: tt.labelLarge),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Categories
                  Text('Categories', style: tt.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: -4,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _cats.isEmpty,
                        onSelected: (_) => setState(() => _cats.clear()),
                      ),
                      for (final c in Category.values)
                        FilterChip(
                          label: Text(c.name),
                          selected: _cats.contains(c),
                          onSelected: (on) {
                            setState(() {
                              if (on) {
                                _cats.add(c);
                              } else {
                                _cats.remove(c);
                              }
                            });
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Sort
                  Text('Sort by', style: tt.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _chip('Date', _sort == EntrySortBy.date, () {
                        setState(() => _sort = EntrySortBy.date);
                      }),
                      _chip('Rating', _sort == EntrySortBy.rating, () {
                        setState(() => _sort = EntrySortBy.rating);
                      }),
                      _chip('Category', _sort == EntrySortBy.category, () {
                        setState(() => _sort = EntrySortBy.category);
                      }),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (_sort != EntrySortBy.category)
                    Row(
                      children: [
                        Switch.adaptive(
                          value: _ascending,
                          onChanged: (v) => setState(() => _ascending = v),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _ascending ? 'Ascending' : 'Descending',
                          style: tt.bodyMedium,
                        ),
                        const Spacer(),
                        Icon(
                          _ascending
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Date range
                  Text('Date range', style: tt.labelLarge),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            (_from == null && _to == null)
                                ? 'Any time'
                                : '${_from != null ? _fmt(_from!) : '…'}  →  ${_to != null ? _fmt(_to!) : '…'}',
                            style: tt.bodyMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickDateRange,
                          icon: const Icon(Icons.event),
                          label: const Text('Pick'),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Clear dates',
                          onPressed: () => setState(() { _from = null; _to = null; }),
                          icon: const Icon(Icons.clear),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom action row
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withOpacity(0.06),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: widget.onClear,
                  child: const Text('Clear'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    widget.onApply(
                      widget.queryController.text,
                      _cats,
                      _sort,
                      _ascending,
                      _from,
                      _to,
                      _favoritesOnly,
                    );
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
