import 'mood.dart';

/// Daily journal record—separate from the multi‑media Entry above.
class JournalEntry {
  final int? id;
  final DateTime date; // stored without time component if you prefer
  final String title;
  final String description;
  final Mood mood;

  const JournalEntry({
    this.id,
    required this.date,
    required this.title,
    required this.description,
    required this.mood,
  });

  JournalEntry copyWith({
    int? id,
    DateTime? date,
    String? title,
    String? description,
    Mood? mood,
  }) =>
      JournalEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        title: title ?? this.title,
        description: description ?? this.description,
        mood: mood ?? this.mood,
      );
}
