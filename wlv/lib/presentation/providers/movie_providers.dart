import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/movie_repository_impl.dart';
import '../../domain/entities/movie.dart';
import '../../domain/usecases/add_movie.dart';
import '../../domain/usecases/get_movies.dart';

final _movieRepoProvider =
    Provider<MovieRepositoryImpl>((_) => MovieRepositoryImpl());

final addMovieUseCaseProvider =
    Provider((ref) => AddMovie(ref.watch(_movieRepoProvider)));

final getMoviesUseCaseProvider =
    Provider((ref) => GetMovies(ref.watch(_movieRepoProvider)));

final moviesFutureProvider = FutureProvider<List<Movie>>(
    (ref) => ref.watch(getMoviesUseCaseProvider).call());
