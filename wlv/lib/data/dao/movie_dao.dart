import '../../domain/entities/movie.dart';
import '../database/app_database.dart';

class MovieDao {
  static const _table = 'movies';

  Future<int> insert(Movie m) async => (await AppDatabase.instance.db)
      .insert(_table, {'title': m.title, 'year': m.year});

  Future<List<Movie>> fetchAll() async {
    final rows =
        await (await AppDatabase.instance.db).query(_table, orderBy: 'id DESC');
    return rows
        .map((r) => Movie(
              id: r['id'] as int,
              title: r['title'] as String,
              year: r['year'] as int,
            ))
        .toList();
  }
}
