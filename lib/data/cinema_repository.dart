import '../models/movie.dart';
import '../models/reservation.dart';
import '../models/screening.dart';
import 'result.dart';

abstract interface class CinemaRepository {
  Future<Result<List<Movie>>> fetchMovies({
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<Result<List<Screening>>> fetchScreenings(
    String movieId, {
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<Result<List<Reservation>>> fetchReservations(
    String userId, {
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<Result<Reservation>> fetchReservationById(String id);

  Future<Result<Reservation>> createReservation(Reservation reservation);

  Future<Result<Reservation>> updateReservation(Reservation reservation);

  Future<Result<void>> deleteReservation(String id);
}
