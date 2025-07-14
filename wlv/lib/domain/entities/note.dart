class Note {
  final int? id;
  final String title;
  final String content;

  const Note({this.id, required this.title, required this.content});

  Note copyWith({int? id, String? title, String? content}) => Note(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
      );
}
