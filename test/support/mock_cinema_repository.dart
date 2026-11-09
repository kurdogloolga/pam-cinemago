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

  @override
  Future<Result<List<Movie>>> fetchMovies() async {
    if (await _shouldFail()) {
      return const Err(_networkError);
    }
    return Ok(List.unmodifiable(mockMovies));
  }

  @override
  Future<Result<List<Screening>>> fetchScreenings(String movieId) async {
    if (await _shouldFail()) {
      return const Err(_networkError);
    }
    return Ok(
      List.unmodifiable(
        _screenings
            .where((screening) => screening.movieId == movieId)
            .map(_copyScreening),
      ),
    );
  }

  @override
  Future<Result<List<Reservation>>> fetchReservations(String userId) async {
    if (await _shouldFail()) {
      return const Err(_networkError);
    }
    return Ok(
      List.unmodifiable(
        _reservations
            .where((reservation) => reservation.userId == userId)
            .map(_copyReservation),
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
