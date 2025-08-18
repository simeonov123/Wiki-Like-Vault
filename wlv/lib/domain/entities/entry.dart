import 'package:flutter/material.dart';
import 'category.dart';

/// Generic vault item: book, movie, TV series, quote, etc.
class Entry {
  final int? id;
  final Category category;
  final String title;
  final String description;
  final List<String> imagePaths;
  final List<String> links;
  final DateTime createdAt;
  final int rating;
  final Color? bgColor;     // actual color (runtime only)
  final String? bgColorHex; // persisted HEX string in DB

  const Entry({
    this.id,
    required this.category,
    required this.title,
    required this.description,
    this.imagePaths = const [],
    this.links = const [],
    required this.createdAt,
    required this.rating,
    this.bgColor,
    this.bgColorHex,
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
    Color? bgColor,
    String? bgColorHex,
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
        bgColor: bgColor ?? this.bgColor,
        bgColorHex: bgColorHex ?? this.bgColorHex,
      );

  /// Convenience: prefer `bgColor` if provided, otherwise decode hex
  Color get effectiveColor {
    if (bgColor != null) return bgColor!;
    if (bgColorHex != null) {
      return colorFromHex(bgColorHex!);
    }
    return Colors.white; // default fallback
  }

  /// Converts HEX string (#AARRGGBB or #RRGGBB) to a Color
  static Color colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Converts Color to HEX string (#AARRGGBB)
  static String colorToHex(Color c) =>
      '#${c.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}
