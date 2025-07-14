import 'package:wlv/domain/repositories/movie_repositories.dart';
import '../../domain/entities/movie.dart';
import '../dao/movie_dao.dart';

class MovieRepositoryImpl implements MovieRepository {
  final _dao = MovieDao();
  @override
  Future<Movie> save(Movie m) async => m.copyWith(id: await _dao.insert(m));
  @override
  Future<List<Movie>> findAll() => _dao.fetchAll();
}
