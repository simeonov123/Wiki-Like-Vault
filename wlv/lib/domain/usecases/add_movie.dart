import 'package:wlv/domain/entities/movie.dart';
import 'package:wlv/domain/repositories/movie_repositories.dart';

class AddMovie {
  final MovieRepository _repo;
  AddMovie(this._repo);
  Future<Movie> call(String title, int year) =>
      _repo.save(Movie(title: title, year: year));
}
