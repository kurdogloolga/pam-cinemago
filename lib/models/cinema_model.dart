import 'package:flutter/foundation.dart';

import '../data/cinema_repository.dart';
import '../data/result.dart';
import 'movie.dart';
import 'reservation.dart';
import 'screening.dart';

class CinemaModel extends ChangeNotifier {
  static const _moviesPageSize = 20;

  final CinemaRepository _repository;

  CinemaModel(this._repository);

  bool _disposed = false;
  List<Movie> _movies = const [];
  final Map<String, List<Screening>> _screeningsByMovieId = {};
  List<Reservation> _reservations = const [];
  final Set<String> _loadingScreeningsMovieIds = {};
  final Map<String, String> _screeningErrorsByMovieId = {};
  String? _activeScreeningsMovieId;

  bool _isMoviesLoading = false;
  bool _isLoadingMoreMovies = false;
  bool _hasMoreMovies = false;
  bool _isReservationsLoading = false;
  bool _isReservationSaving = false;
  bool _hasLoadedReservations = false;
  int _reservationsVersion = 0;
  int _moviesPage = 1;
  int _moviesRequestId = 0;
  String _movieSearch = '';

  String? _moviesError;
  String? _moviesMoreError;
  String? _reservationsError;
  String? _reservationError;

  List<Movie> get movies => List.unmodifiable(_movies);
  List<Screening> get screenings =>
      screeningsForMovie(_activeScreeningsMovieId ?? '');
  List<Reservation> get reservations => List.unmodifiable(_reservations);
  int get activeReservationCount => _reservations
      .where((reservation) => reservation.status != 'Отменено')
      .length;
  bool get hasLoadedReservations => _hasLoadedReservations;
  Movie? movieById(String id) =>
      _movies.where((movie) => movie.id == id).firstOrNull;

  List<Screening> screeningsForMovie(String movieId) =>
      List.unmodifiable(_screeningsByMovieId[movieId] ?? const []);

  Screening? screeningById(String id) {
    for (final screenings in _screeningsByMovieId.values) {
      final matches = screenings.where((screening) => screening.id == id);
      if (matches.isNotEmpty) {
        return matches.first;
      }
    }
    return null;
  }

  bool get isMoviesLoading => _isMoviesLoading;
  bool get isLoadingMoreMovies => _isLoadingMoreMovies;
  bool get hasMoreMovies => _hasMoreMovies;
  bool get isScreeningsLoading =>
      _activeScreeningsMovieId != null &&
      _loadingScreeningsMovieIds.contains(_activeScreeningsMovieId);
  bool isScreeningsLoadingFor(String movieId) =>
      _loadingScreeningsMovieIds.contains(movieId);
  bool get isAnyScreeningsLoading => _loadingScreeningsMovieIds.isNotEmpty;
  bool get isReservationsLoading => _isReservationsLoading;
  bool get isReservationSaving => _isReservationSaving;

  String? get moviesError => _moviesError;
  String? get moviesMoreError => _moviesMoreError;
  String get movieSearch => _movieSearch;
  String? get screeningsError => _activeScreeningsMovieId == null
      ? null
      : _screeningErrorsByMovieId[_activeScreeningsMovieId];
  String? screeningsErrorFor(String movieId) =>
      _screeningErrorsByMovieId[movieId];
  String? get firstScreeningsError =>
      _screeningErrorsByMovieId.values.firstOrNull;
  String? get reservationsError => _reservationsError;
  String? get reservationError => _reservationError;

  bool hasLoadedScreeningsFor(String movieId) =>
      _screeningsByMovieId.containsKey(movieId);

  Future<void> loadMovies({String? search}) async {
    if (_disposed) return;
    if (search != null) _movieSearch = search.trim();
    final requestId = ++_moviesRequestId;
    _moviesPage = 1;
    _hasMoreMovies = false;
    _isLoadingMoreMovies = false;
    _moviesMoreError = null;
    _movies = const [];
    _isMoviesLoading = true;
    _moviesError = null;
    notifyListeners();

    final result = await _repository.fetchMovies(
      page: 1,
      limit: _moviesPageSize,
      search: _movieSearch.isEmpty ? null : _movieSearch,
    );
    if (_disposed || requestId != _moviesRequestId) return;
    switch (result) {
      case Ok<List<Movie>>(value: final movies):
        _movies = List.unmodifiable(movies);
        _hasMoreMovies = movies.length == _moviesPageSize;
      case Err<List<Movie>>(msg: final message):
        _moviesError = message;
    }

    _isMoviesLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreMovies() async {
    if (_disposed ||
        _isMoviesLoading ||
        _isLoadingMoreMovies ||
        !_hasMoreMovies) {
      return;
    }

    final requestId = _moviesRequestId;
    final page = _moviesPage + 1;
    _isLoadingMoreMovies = true;
    _moviesMoreError = null;

    final result = await _repository.fetchMovies(
      page: page,
      limit: _moviesPageSize,
      search: _movieSearch.isEmpty ? null : _movieSearch,
    );
    if (_disposed || requestId != _moviesRequestId) return;

    switch (result) {
      case Ok<List<Movie>>(value: final movies):
        final existingIds = _movies.map((movie) => movie.id).toSet();
        _movies = List.unmodifiable([
          ..._movies,
          ...movies.where((movie) => existingIds.add(movie.id)),
        ]);
        _moviesPage = page;
        _hasMoreMovies = movies.length == _moviesPageSize;
      case Err<List<Movie>>(msg: final message):
        _moviesMoreError = message;
    }

    _isLoadingMoreMovies = false;
    notifyListeners();
  }

  Future<void> loadScreenings(String movieId) async {
    if (_disposed) return;
    _activeScreeningsMovieId = movieId;
    _screeningErrorsByMovieId.remove(movieId);
    _loadingScreeningsMovieIds.add(movieId);
    notifyListeners();

    final result = await _repository.fetchScreenings(movieId);
    if (_disposed) return;
    switch (result) {
      case Ok<List<Screening>>(value: final screenings):
        _screeningsByMovieId[movieId] = List.unmodifiable(screenings);
        _screeningErrorsByMovieId.remove(movieId);
      case Err<List<Screening>>(msg: final message):
        _screeningErrorsByMovieId[movieId] = message;
    }

    _loadingScreeningsMovieIds.remove(movieId);
    notifyListeners();
  }

  Future<void> loadAllScreenings() async {
    if (_disposed) return;
    await Future.wait(
      _movies
          .where(
            (movie) =>
                !hasLoadedScreeningsFor(movie.id) &&
                !isScreeningsLoadingFor(movie.id),
          )
          .map((movie) => loadScreenings(movie.id)),
    );
  }

  Future<void> loadReservations(String userId) async {
    if (_disposed) return;
    final version = _reservationsVersion;
    _isReservationsLoading = true;
    _reservationsError = null;
    notifyListeners();

    final result = await _repository.fetchReservations(userId);
    if (_disposed) return;
    if (version != _reservationsVersion) {
      await loadReservations(userId);
      return;
    }
    switch (result) {
      case Ok<List<Reservation>>(value: final reservations):
        _reservations = List.unmodifiable(reservations);
        _hasLoadedReservations = true;
      case Err<List<Reservation>>(msg: final message):
        _reservationsError = message;
    }

    _isReservationsLoading = false;
    notifyListeners();
  }

  Future<String?> createReservation(Reservation reservation) async {
    if (_disposed) return 'Сессия завершена';
    _isReservationSaving = true;
    _reservationError = null;
    notifyListeners();

    final result = await _repository.createReservation(reservation);
    if (_disposed) return 'Сессия завершена';
    switch (result) {
      case Ok<Reservation>(value: final created):
        _reservationsVersion++;
        _reservations = List.unmodifiable([..._reservations, created]);
        _isReservationSaving = false;
        notifyListeners();
        _refreshScreening(created.screeningId);
        return null;
      case Err<Reservation>(msg: final message):
        _reservationError = message;
        _isReservationSaving = false;
        notifyListeners();
        if (message == 'Одно или несколько мест уже заняты') {
          _refreshScreening(reservation.screeningId);
        }
        return message;
    }
  }

  Future<String?> cancelReservation(String reservationId) async {
    if (_disposed) return 'Сессия завершена';
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
      return _reservationError;
    }

    final result = await _repository.updateReservation(
      existing.first.copyWith(status: 'Отменено'),
    );
    if (_disposed) return 'Сессия завершена';
    switch (result) {
      case Ok<Reservation>(value: final updated):
        _reservationsVersion++;
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
        _refreshScreening(updated.screeningId);
        return null;
      case Err<Reservation>(msg: final message):
        _reservationError = message;
        _isReservationSaving = false;
        notifyListeners();
        return message;
    }
  }

  void _refreshScreening(String screeningId) {
    final screening = screeningById(screeningId);
    if (screening != null) {
      loadScreenings(screening.movieId);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
