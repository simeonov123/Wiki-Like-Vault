import 'package:wlv/domain/entities/movie.dart';
import 'package:wlv/domain/repositories/movie_repositories.dart';

class GetMovies {
  final MovieRepository _repo;
  GetMovies(this._repo);
  Future<List<Movie>> call() => _repo.findAll();
}
