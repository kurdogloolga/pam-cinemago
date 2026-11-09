import 'package:cinemago/models/movie.dart';
import 'package:cinemago/models/reservation.dart';
import 'package:cinemago/models/screening.dart';
import 'package:cinemago/data/cinema_repository.dart';
import 'package:cinemago/data/result.dart';

import 'mock_data.dart' show mockMovies, mockReservations, mockScreenings;

class MockCinemaRepository implements CinemaRepository {
  static const _latency = Duration(milliseconds: 800);
  static const _networkError = 'Сервер не отвечает — повторите попытку';

  final List<Screening> _screenings = mockScreenings
      .map(_copyScreening)
      .toList();
  final List<Reservation> _reservations = mockReservations
      .map(_copyReservation)
      .toList();
  int _nextReservationNumber = 1000;

  bool simulateError = false;
  String? lastMovieSearch;
  int? lastMoviePage;
  List<Movie>? movieSource;

  @override
  Future<Result<List<Movie>>> fetchMovies({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    lastMovieSearch = search;
    lastMoviePage = page;
    if (await _shouldFail()) {
      return const Err(_networkError);
    }
    final query = search?.trim().toLowerCase() ?? '';
    final filtered = (movieSource ?? mockMovies).where(
      (movie) =>
          query.isEmpty ||
          movie.title.toLowerCase().contains(query) ||
          movie.genre.toLowerCase().contains(query),
    );
    return Ok(List.unmodifiable(filtered.skip((page - 1) * limit).take(limit)));
  }

  @override
  Future<Result<List<Screening>>> fetchScreenings(
    String movieId, {
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    if (await _shouldFail()) {
      return const Err(_networkError);
    }
    final query = search?.trim().toLowerCase() ?? '';
    final filtered = _screenings.where(
      (screening) =>
          screening.movieId == movieId &&
          (query.isEmpty || screening.hall.toLowerCase().contains(query)),
    );
    return Ok(
      List.unmodifiable(
        filtered.skip((page - 1) * limit).take(limit).map(_copyScreening),
      ),
    );
  }

  @override
  Future<Result<List<Reservation>>> fetchReservations(
    String userId, {
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    if (await _shouldFail()) {
      return const Err(_networkError);
    }
    final query = search?.trim().toLowerCase() ?? '';
    final filtered = _reservations.where(
      (reservation) =>
          reservation.userId == userId &&
          (query.isEmpty ||
              reservation.status.toLowerCase().contains(query) ||
              reservation.seats.any(
                (seat) => seat.toLowerCase().contains(query),
              )),
    );
    return Ok(
      List.unmodifiable(
        filtered.skip((page - 1) * limit).take(limit).map(_copyReservation),
      ),
    );
  }

  @override
  Future<Result<Reservation>> fetchReservationById(String id) async {
    if (await _shouldFail()) {
      return const Err(_networkError);
    }
    final index = _reservations.indexWhere(
      (reservation) => reservation.id == id,
    );
    if (index == -1) {
      return const Err('Бронирование не найдено');
    }
    return Ok(_copyReservation(_reservations[index]));
  }

  @override
  Future<Result<Reservation>> createReservation(Reservation reservation) async {
    if (await _shouldFail()) {
      return const Err(_networkError);
    }
    final screeningExists = _screenings.any(
      (screening) => screening.id == reservation.screeningId,
    );
    if (!screeningExists) {
      return const Err('Сеанс не найден');
    }

    final created = _copyReservation(
      reservation.copyWith(id: 'r$_nextReservationNumber'),
    );
    _nextReservationNumber++;
    _reservations.add(created);
    return Ok(_copyReservation(created));
  }

  @override
  Future<Result<Reservation>> updateReservation(Reservation reservation) async {
    if (await _shouldFail()) {
      return const Err(_networkError);
    }
    final index = _reservations.indexWhere((item) => item.id == reservation.id);
    if (index == -1) {
      return const Err('Бронирование не найдено');
    }

    final updated = _copyReservation(reservation);
    _reservations[index] = updated;
    return Ok(_copyReservation(updated));
  }

  @override
  Future<Result<void>> deleteReservation(String id) async {
    if (await _shouldFail()) {
      return const Err(_networkError);
    }
    final index = _reservations.indexWhere(
      (reservation) => reservation.id == id,
    );
    if (index == -1) {
      return const Err('Бронирование не найдено');
    }
    _reservations.removeAt(index);
    return const Ok(null);
  }

  Future<bool> _shouldFail() async {
    await Future<void>.delayed(_latency);
    return simulateError;
  }
}

Screening _copyScreening(Screening screening) {
  return Screening(
    id: screening.id,
    movieId: screening.movieId,
    hall: screening.hall,
    dateTime: screening.dateTime,
    price: screening.price,
    seatsTaken: List.unmodifiable(screening.seatsTaken),
  );
}

Reservation _copyReservation(Reservation reservation) {
  return Reservation(
    id: reservation.id,
    screeningId: reservation.screeningId,
    userId: reservation.userId,
    seats: List.unmodifiable(reservation.seats),
    totalPrice: reservation.totalPrice,
    status: reservation.status,
  );
}
