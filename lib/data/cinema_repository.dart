import '../models/movie.dart';
import '../models/reservation.dart';
import '../models/screening.dart';
import 'result.dart';

abstract interface class CinemaRepository {
  Future<Result<List<Movie>>> fetchMovies();

  Future<Result<List<Screening>>> fetchScreenings(String movieId);

  Future<Result<List<Reservation>>> fetchReservations(String userId);

  Future<Result<Reservation>> fetchReservationById(String id);

  Future<Result<Reservation>> createReservation(Reservation reservation);

  Future<Result<Reservation>> updateReservation(Reservation reservation);

  Future<Result<void>> deleteReservation(String id);
}
