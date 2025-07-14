class Movie {
  final int? id;
  final String title;
  final int year;
  const Movie({this.id, required this.title, required this.year});
  Movie copyWith({int? id, String? title, int? year}) => Movie(
      id: id ?? this.id, title: title ?? this.title, year: year ?? this.year);
}
