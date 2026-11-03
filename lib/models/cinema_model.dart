import 'package:flutter/foundation.dart';

import '../data/cinema_repository.dart';
import '../data/result.dart';
import 'movie.dart';
import 'reservation.dart';
import 'screening.dart';

class CinemaModel extends ChangeNotifier {
  final CinemaRepository _repository;

  CinemaModel(this._repository);

  List<Movie> _movies = const [];
  List<Screening> _screenings = const [];
  List<Reservation> _reservations = const [];

  bool _isMoviesLoading = false;
  bool _isScreeningsLoading = false;
  bool _isReservationsLoading = false;
  bool _isReservationSaving = false;

  String? _moviesError;
  String? _screeningsError;
  String? _reservationsError;
  String? _reservationError;

  List<Movie> get movies => List.unmodifiable(_movies);
  List<Screening> get screenings => List.unmodifiable(_screenings);
  List<Reservation> get reservations => List.unmodifiable(_reservations);

  bool get isMoviesLoading => _isMoviesLoading;
  bool get isScreeningsLoading => _isScreeningsLoading;
  bool get isReservationsLoading => _isReservationsLoading;
  bool get isReservationSaving => _isReservationSaving;

  String? get moviesError => _moviesError;
  String? get screeningsError => _screeningsError;
  String? get reservationsError => _reservationsError;
  String? get reservationError => _reservationError;

  Future<void> loadMovies() async {
    _isMoviesLoading = true;
    _moviesError = null;
    notifyListeners();

    final result = await _repository.fetchMovies();
    switch (result) {
      case Ok<List<Movie>>(value: final movies):
        _movies = List.unmodifiable(movies);
      case Err<List<Movie>>(msg: final message):
        _moviesError = message;
    }

    _isMoviesLoading = false;
    notifyListeners();
  }

  Future<void> loadScreenings(String movieId) async {
    _isScreeningsLoading = true;
    _screeningsError = null;
    notifyListeners();

    final result = await _repository.fetchScreenings(movieId);
    switch (result) {
      case Ok<List<Screening>>(value: final screenings):
        _screenings = List.unmodifiable(screenings);
      case Err<List<Screening>>(msg: final message):
        _screeningsError = message;
    }

    _isScreeningsLoading = false;
    notifyListeners();
  }

  Future<void> loadReservations(String userId) async {
    _isReservationsLoading = true;
    _reservationsError = null;
    notifyListeners();

    final result = await _repository.fetchReservations(userId);
    switch (result) {
      case Ok<List<Reservation>>(value: final reservations):
        _reservations = List.unmodifiable(reservations);
      case Err<List<Reservation>>(msg: final message):
        _reservationsError = message;
    }

    _isReservationsLoading = false;
    notifyListeners();
  }

  Future<bool> createReservation(Reservation reservation) async {
    _isReservationSaving = true;
    _reservationError = null;
    notifyListeners();

    final result = await _repository.createReservation(reservation);
    switch (result) {
      case Ok<Reservation>(value: final created):
        _reservations = List.unmodifiable([..._reservations, created]);
        _isReservationSaving = false;
        notifyListeners();
        return true;
      case Err<Reservation>(msg: final message):
        _reservationError = message;
        _isReservationSaving = false;
        notifyListeners();
        return false;
    }
  }

  Future<bool> cancelReservation(String reservationId) async {
    _isReservationSaving = true;
    _reservationError = null;
    notifyListeners();

    final existing = _reservations.where(
      (reservation) => reservation.id == reservationId,
    );
    if (existing.isEmpty) {
      _reservationError = 'Бронирование не найдено';
      _isReservationSaving = false;
      notifyListeners();
      return false;
    }

    final result = await _repository.updateReservation(
      existing.first.copyWith(status: 'Отменено'),
    );
    switch (result) {
      case Ok<Reservation>(value: final updated):
        _reservations = List.unmodifiable(
          _reservations
              .map(
                (reservation) =>
                    reservation.id == reservationId ? updated : reservation,
              )
              .toList(),
        );
        _isReservationSaving = false;
        notifyListeners();
        return true;
      case Err<Reservation>(msg: final message):
        _reservationError = message;
        _isReservationSaving = false;
        notifyListeners();
        return false;
    }
  }
}
