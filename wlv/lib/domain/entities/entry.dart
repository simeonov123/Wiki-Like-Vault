import 'category.dart';

/// Generic vault item: book, movie, TV series, quote, etc.
///
/// * Lists (images & links) will be persisted as JSON strings by the DAO.
/// * `rating` is 1–10 inclusive.
class Entry {
  final int? id;
  final Category category;
  final String title;
  final String description;
  final List<String> imagePaths; // local/remote URIs
  final List<String> links; // arbitrary URLs
  final DateTime createdAt;
  final int rating;

  const Entry({
    this.id,
    required this.category,
    required this.title,
    required this.description,
    this.imagePaths = const [],
    this.links = const [],
    required this.createdAt,
    required this.rating,
  });

  Entry copyWith({
    int? id,
    Category? category,
    String? title,
    String? description,
    List<String>? imagePaths,
    List<String>? links,
    DateTime? createdAt,
    int? rating,
  }) =>
      Entry(
        id: id ?? this.id,
        category: category ?? this.category,
        title: title ?? this.title,
        description: description ?? this.description,
        imagePaths: imagePaths ?? this.imagePaths,
        links: links ?? this.links,
        createdAt: createdAt ?? this.createdAt,
        rating: rating ?? this.rating,
      );
}
