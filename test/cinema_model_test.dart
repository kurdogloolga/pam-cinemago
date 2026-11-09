import 'dart:async';

import 'package:cinemago/data/cinema_repository.dart';
import 'package:cinemago/data/result.dart';
import 'package:cinemago/models/cinema_model.dart';
import 'package:cinemago/models/movie.dart';
import 'package:cinemago/models/reservation.dart';
import 'package:cinemago/models/screening.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CinemaModel', () {
    test('loads movies and exposes loading and data states', () async {
      final repository = _FakeCinemaRepository();
      final model = CinemaModel(repository);
      var notificationCount = 0;
      model.addListener(() => notificationCount++);

      final loading = model.loadMovies();
      expect(model.isMoviesLoading, isTrue);
      expect(notificationCount, 1);

      await loading;

      expect(model.isMoviesLoading, isFalse);
      expect(model.movies, [repository.movie]);
      expect(model.moviesError, isNull);
      expect(notificationCount, 2);
    });

    test('keeps repository errors available and supports retry', () async {
      final repository = _FakeCinemaRepository()..failMovies = true;
      final model = CinemaModel(repository);

      await model.loadMovies();

      expect(model.movies, isEmpty);
      expect(model.moviesError, 'Каталог недоступен');

      repository.failMovies = false;
      await model.loadMovies();

      expect(model.movies, [repository.movie]);
      expect(model.moviesError, isNull);
    });

    test(
      'searches and appends movie pages, then stops at the final page',
      () async {
        final repository = _FakeCinemaRepository()
          ..additionalMovies = List.generate(
            44,
            (index) => Movie(
              id: 'm${index + 2}',
              title: 'Фильм ${index + 1}',
              genre: 'драма',
              year: null,
              director: null,
              durationMin: 90,
              posterUrl: '',
              rating: 7,
              description: null,
            ),
          );
        final model = CinemaModel(repository);

        await model.loadMovies(search: ' драма ');
        expect(model.movieSearch, 'драма');
        expect(model.movies, hasLength(20));
        expect(model.hasMoreMovies, isTrue);

        await model.loadMoreMovies();
        expect(model.movies, hasLength(40));
        expect(model.hasMoreMovies, isTrue);

        await model.loadMoreMovies();
        expect(model.movies, hasLength(45));
        expect(model.hasMoreMovies, isFalse);
        expect(repository.requestedPages, [1, 2, 3]);
        expect(repository.requestedSearches, ['драма', 'драма', 'драма']);

        await model.loadMoreMovies();
        expect(repository.requestedPages, [1, 2, 3]);
      },
    );

    test(
      'retries the next movie page without losing already loaded movies',
      () async {
        final repository = _FakeCinemaRepository()
          ..additionalMovies = List.generate(
            20,
            (index) => Movie(
              id: 'm${index + 2}',
              title: 'Фильм ${index + 1}',
              genre: 'драма',
              year: null,
              director: null,
              durationMin: 90,
              posterUrl: '',
              rating: 7,
              description: null,
            ),
          );
        final model = CinemaModel(repository);
        await model.loadMovies(search: 'драма');
        repository.failNextMoviePage = true;

        await model.loadMoreMovies();
        expect(model.movies, hasLength(20));
        expect(model.moviesMoreError, 'Каталог недоступен');
        expect(model.hasMoreMovies, isTrue);

        await model.loadMoreMovies();
        expect(model.movies, hasLength(21));
        expect(model.moviesMoreError, isNull);
        expect(repository.requestedPages, [1, 2, 2]);
        expect(repository.requestedSearches, ['драма', 'драма', 'драма']);
      },
    );

    test('ignores an older movie search response that finishes last', () async {
      final repository = _RacingMovieRepository();
      final model = CinemaModel(repository);
      final olderSearch = model.loadMovies(search: 'older');
      final newerSearch = model.loadMovies(search: 'newer');

      repository.newer.complete(Ok([repository.resultMovie('Newer result')]));
      await newerSearch;
      repository.older.complete(Ok([repository.resultMovie('Older result')]));
      await olderSearch;

      expect(model.movieSearch, 'newer');
      expect(model.movies.single.title, 'Newer result');
      expect(model.isMoviesLoading, isFalse);
    });

    test('loads screenings and reservations using their identifiers', () async {
      final repository = _FakeCinemaRepository();
      final model = CinemaModel(repository);

      await model.loadScreenings('m1');
      await model.loadReservations('u1');

      expect(model.screenings, [repository.screening]);
      expect(model.reservations, [repository.reservation]);
      expect(model.activeReservationCount, 1);
      expect(repository.lastMovieId, 'm1');
      expect(repository.lastUserId, 'u1');
    });

    test('creates and cancels reservations in model state', () async {
      final repository = _FakeCinemaRepository();
      final model = CinemaModel(repository);
      await model.loadReservations('u1');

      final created = await model.createReservation(
        const Reservation(
          id: 'temporary',
          screeningId: 's1',
          userId: 'u1',
          seats: ['B2'],
          totalPrice: 95,
          status: 'Ожидает подтверждения',
        ),
      );
      expect(created, isNull);
      expect(model.reservations.last.id, 'created-1');
      expect(model.activeReservationCount, 2);

      final cancelled = await model.cancelReservation('created-1');

      expect(cancelled, isNull);
      expect(model.reservations.last.status, 'Отменено');
      expect(model.activeReservationCount, 1);
      expect(model.reservationError, isNull);
    });

    test('exposes reservation mutation errors', () async {
      final repository = _FakeCinemaRepository()..failReservationWrites = true;
      final model = CinemaModel(repository);

      final created = await model.createReservation(repository.reservation);

      expect(created, 'Бронирование недоступно');
      expect(model.isReservationSaving, isFalse);
      expect(model.reservationError, 'Бронирование недоступно');

      repository.failReservationWrites = false;
      await model.loadReservations('u1');
      repository.failReservationWrites = true;
      final cancelled = await model.cancelReservation('r1');

      expect(cancelled, 'Бронирование недоступно');
      expect(model.reservationError, 'Бронирование недоступно');
    });
  });
}

class _RacingMovieRepository extends _FakeCinemaRepository {
  final older = Completer<Result<List<Movie>>>();
  final newer = Completer<Result<List<Movie>>>();

  Movie resultMovie(String title) => Movie(
    id: movie.id,
    title: title,
    genre: movie.genre,
    year: movie.year,
    director: movie.director,
    durationMin: movie.durationMin,
    posterUrl: movie.posterUrl,
    rating: movie.rating,
    description: movie.description,
  );

  @override
  Future<Result<List<Movie>>> fetchMovies({
    int page = 1,
    int limit = 20,
    String? search,
  }) => search == 'older' ? older.future : newer.future;
}

class _FakeCinemaRepository implements CinemaRepository {
  final movie = const Movie(
    id: 'm1',
    title: 'Тестовый фильм',
    genre: 'драма',
    year: 2026,
    director: 'Режиссёр',
    durationMin: 100,
    posterUrl: '',
    rating: 8,
    description: 'Описание',
  );
  final screening = Screening(
    id: 's1',
    movieId: 'm1',
    hall: 'Зал 1',
    dateTime: DateTime(2026, 11, 3, 18),
    price: 95,
    seatsTaken: const [],
  );
  final reservation = const Reservation(
    id: 'r1',
    screeningId: 's1',
    userId: 'u1',
    seats: ['A1'],
    totalPrice: 95,
    status: 'Подтверждено',
  );

  bool failMovies = false;
  bool failNextMoviePage = false;
  bool failReservationWrites = false;
  String? lastMovieId;
  String? lastUserId;
  int _nextId = 1;
  final List<Reservation> _reservations = [];
  List<Movie> additionalMovies = const [];
  final List<int> requestedPages = [];
  final List<String?> requestedSearches = [];

  @override
  Future<Result<List<Movie>>> fetchMovies({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    requestedPages.add(page);
    requestedSearches.add(search);
    if (failMovies || (failNextMoviePage && page > 1)) {
      failNextMoviePage = false;
      return const Err('Каталог недоступен');
    }
    final filtered = [movie, ...additionalMovies].where((item) {
      final query = search?.toLowerCase() ?? '';
      return query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.genre.toLowerCase().contains(query);
    });
    return Ok(filtered.skip((page - 1) * limit).take(limit).toList());
  }

  @override
  Future<Result<List<Screening>>> fetchScreenings(
    String movieId, {
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    lastMovieId = movieId;
    return Ok(movieId == screening.movieId ? [screening] : []);
  }

  @override
  Future<Result<List<Reservation>>> fetchReservations(
    String userId, {
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    lastUserId = userId;
    return Ok([
      if (userId == reservation.userId) reservation,
      ..._reservations.where((item) => item.userId == userId),
    ]);
  }

  @override
  Future<Result<Reservation>> fetchReservationById(String id) async {
    final matches = _reservations.where((item) => item.id == id);
    return matches.isEmpty ? const Err('Не найдено') : Ok(matches.first);
  }

  @override
  Future<Result<Reservation>> createReservation(
    Reservation newReservation,
  ) async {
    if (failReservationWrites) {
      return const Err('Бронирование недоступно');
    }
    final created = newReservation.copyWith(id: 'created-${_nextId++}');
    _reservations.add(created);
    return Ok(created);
  }

  @override
  Future<Result<Reservation>> updateReservation(
    Reservation updatedReservation,
  ) async {
    if (failReservationWrites) {
      return const Err('Бронирование недоступно');
    }
    final index = _reservations.indexWhere(
      (item) => item.id == updatedReservation.id,
    );
    if (index == -1) {
      return const Err('Не найдено');
    }
    _reservations[index] = updatedReservation;
    return Ok(updatedReservation);
  }

  @override
  Future<Result<void>> deleteReservation(String id) async {
    _reservations.removeWhere((item) => item.id == id);
    return const Ok(null);
  }
}
