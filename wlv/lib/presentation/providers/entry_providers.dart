import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/entry_repository_impl.dart';
import '../../domain/entities/entry.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/add_entry.dart';
import '../../domain/usecases/get_entries.dart';
import '../../domain/usecases/update_entry.dart';
import '../../domain/usecases/delete_entry.dart';

final _entryRepo = Provider((_) => EntryRepositoryImpl());

final addEntryUcProvider      = Provider((ref) => AddEntry(ref.watch(_entryRepo)));
final getEntriesUcProvider    = Provider((ref) => GetEntries(ref.watch(_entryRepo)));
final updateEntryUcProvider   = Provider((ref) => UpdateEntry(ref.watch(_entryRepo)));
final deleteEntryUcProvider   = Provider((ref) => DeleteEntry(ref.watch(_entryRepo)));

final entriesFutureProvider = FutureProvider<List<Entry>>(
  (ref) => ref.watch(getEntriesUcProvider).call(),
);

/* ───────────── Favorites (persisted with SharedPreferences) ───────────── */

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<int>>((ref) {
  final n = FavoritesNotifier();
  n.load(); // fire-and-forget load
  return n;
});

class FavoritesNotifier extends StateNotifier<Set<int>> {
  FavoritesNotifier() : super(<int>{});

  static const _prefsKey = 'favorite_entry_ids';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<int>();
      state = list.toSet();
    } catch (_) {
      final list = prefs.getStringList(_prefsKey);
      if (list != null) {
        state = list.map(int.parse).toSet();
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toList()));
  }

  bool isFavorite(int? id) => id != null && state.contains(id);

  Future<void> toggle(int? id) async {
    if (id == null) return;
    final s = Set<int>.from(state);
    if (s.contains(id)) {
      s.remove(id);
    } else {
      s.add(id);
    }
    state = s;
    await _save();
  }

  Future<void> removeIfPresent(int? id) async {
    if (id == null) return;
    if (!state.contains(id)) return;
    final s = Set<int>.from(state)..remove(id);
    state = s;
    await _save();
  }
}

/* ───────────── Filtering & sorting state ───────────── */

enum EntrySortBy { date, rating, category }

class EntriesFilter {
  final String query;
  final EntrySortBy sortBy;
  final bool ascending;             // ignored when sortBy == category
  final Set<Category> categories;   // multi-select
  final DateTime? from;             // inclusive
  final DateTime? to;               // inclusive
  final bool favoritesOnly;         // NEW

  const EntriesFilter({
    this.query = '',
    this.sortBy = EntrySortBy.date,
    this.ascending = false,
    this.categories = const {},
    this.from,
    this.to,
    this.favoritesOnly = false,
  });

  EntriesFilter copyWith({
    String? query,
    EntrySortBy? sortBy,
    bool? ascending,
    Set<Category>? categories,
    DateTime? from,
    DateTime? to,
    bool? favoritesOnly,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return EntriesFilter(
      query: query ?? this.query,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      categories: categories ?? this.categories,
      from: clearFrom ? null : (from ?? this.from),
      to:   clearTo   ? null : (to   ?? this.to),
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }
}

class EntriesFilterNotifier extends StateNotifier<EntriesFilter> {
  EntriesFilterNotifier() : super(const EntriesFilter());

  void setQuery(String q) => state = state.copyWith(query: q);
  void setSort(EntrySortBy s) => state = state.copyWith(sortBy: s);
  void toggleAscending() => state = state.copyWith(ascending: !state.ascending);

  void setCategories(Set<Category> set) => state = state.copyWith(categories: set);
  void toggleCategory(Category c) {
    final s = Set<Category>.from(state.categories);
    if (s.contains(c)) {
      s.remove(c);
    } else {
      s.add(c);
    }
    state = state.copyWith(categories: s);
  }

  void setDateRange({DateTime? from, DateTime? to}) =>
      state = state.copyWith(from: from, to: to);
  void clearDates() => state = state.copyWith(clearFrom: true, clearTo: true);

  void setFavoritesOnly(bool v) => state = state.copyWith(favoritesOnly: v);

  void clear() => state = const EntriesFilter();
}

final entriesFilterProvider =
    StateNotifierProvider<EntriesFilterNotifier, EntriesFilter>(
        (ref) => EntriesFilterNotifier());

/// Final, filtered + sorted list to render
final entriesFilteredProvider = Provider<AsyncValue<List<Entry>>>((ref) {
  final base        = ref.watch(entriesFutureProvider);
  final filter      = ref.watch(entriesFilterProvider);
  final favorites   = ref.watch(favoritesProvider);

  return base.whenData((items) {
    Iterable<Entry> list = items;

    if (filter.favoritesOnly) {
      list = list.where((e) => favorites.contains(e.id));
    }

    if (filter.categories.isNotEmpty) {
      list = list.where((e) => filter.categories.contains(e.category));
    }

    if (filter.from != null) {
      list = list.where((e) => !e.createdAt.isBefore(DateTime(filter.from!.year, filter.from!.month, filter.from!.day)));
    }
    if (filter.to != null) {
      final nextDay = DateTime(filter.to!.year, filter.to!.month, filter.to!.day).add(const Duration(days: 1));
      list = list.where((e) => e.createdAt.isBefore(nextDay));
    }

    final q = filter.query.trim().toLowerCase();
    if (q.isNotEmpty) {
      int score(Entry e) {
        final title = e.title.toLowerCase();
        final desc  = e.description.toLowerCase();
        int s = 0;
        if (title.contains(q)) {
          s += 1000 + _countOccurrences(title, q) * 5;
        }
        if (desc.contains(q)) {
          s += 200 + _countOccurrences(desc, q);
        }
        s += (e.rating * 2);
        s += e.createdAt.millisecondsSinceEpoch ~/ 100000000;
        return s;
      }
      list = list
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q))
          .toList()
        ..sort((a, b) => score(b).compareTo(score(a)));
    }

    int cmp(Entry a, Entry b) {
      switch (filter.sortBy) {
        case EntrySortBy.date:
          return a.createdAt.compareTo(b.createdAt);
        case EntrySortBy.rating:
          return a.rating.compareTo(b.rating);
        case EntrySortBy.category:
          return a.category.index.compareTo(b.category.index);
      }
    }

    final applyAscending = filter.sortBy == EntrySortBy.category
        ? true
        : filter.ascending;

    final sorted = list.toList()..sort((a, b) {
      final r = cmp(a, b);
      return applyAscending ? r : -r;
    });

    return sorted;
  });
});

int _countOccurrences(String text, String needle) {
  if (needle.isEmpty) return 0;
  int count = 0, idx = 0;
  while (true) {
    idx = text.indexOf(needle, idx);
    if (idx == -1) break;
    count++;
    idx += needle.length;
  }
  return count;
}

/* ───────────── Pagination (25/page) ───────────── */

const entriesPageSize = 25;

final currentPageProvider = StateProvider<int>((_) => 0); // zero-based

final pagedEntriesProvider = Provider<AsyncValue<List<Entry>>>((ref) {
  final filtered = ref.watch(entriesFilteredProvider);
  final page     = ref.watch(currentPageProvider);
  return filtered.whenData((list) {
    final start = page * entriesPageSize;
    final end   = (start + entriesPageSize).clamp(0, list.length);
    if (start >= list.length) return <Entry>[];
    return list.sublist(start, end);
  });
});

final totalPagesProvider = Provider<int>((ref) {
  final filtered = ref.watch(entriesFilteredProvider).asData?.value ?? const <Entry>[];
  final total = (filtered.length / entriesPageSize).ceil();
  return total == 0 ? 1 : total;
});

/// Reset page to 0 whenever filters change so users see the first page of results.
final _pageResetOnFilterProvider = Provider((ref) {
  ref.listen<EntriesFilter>(entriesFilterProvider, (_, __) {
    ref.read(currentPageProvider.notifier).state = 0;
  });
  return null;
});
