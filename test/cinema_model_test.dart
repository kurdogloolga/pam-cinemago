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
  bool failReservationWrites = false;
  String? lastMovieId;
  String? lastUserId;
  int _nextId = 1;
  final List<Reservation> _reservations = [];

  @override
  Future<Result<List<Movie>>> fetchMovies() async {
    return failMovies ? const Err('Каталог недоступен') : Ok([movie]);
  }

  @override
  Future<Result<List<Screening>>> fetchScreenings(String movieId) async {
    lastMovieId = movieId;
    return Ok(movieId == screening.movieId ? [screening] : []);
  }

  @override
  Future<Result<List<Reservation>>> fetchReservations(String userId) async {
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
