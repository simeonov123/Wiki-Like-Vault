import 'package:wlv/domain/entities/movie.dart';

abstract class MovieRepository {
  Future<Movie> save(Movie m);
  Future<List<Movie>> findAll();
}
