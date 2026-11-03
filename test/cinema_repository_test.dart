import 'package:cinemago/data/mock_cinema_repository.dart';
import 'package:cinemago/data/result.dart';
import 'package:cinemago/models/movie.dart';
import 'package:cinemago/models/reservation.dart';
import 'package:cinemago/models/screening.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockCinemaRepository', () {
    test('returns movies and screenings for the requested movie', () async {
      final repository = MockCinemaRepository();

      final moviesResult = await repository.fetchMovies();
      final screeningsResult = await repository.fetchScreenings('m1');

      expect(moviesResult, isA<Ok<List<Movie>>>());
      expect((moviesResult as Ok<List<Movie>>).value, hasLength(8));
      expect(screeningsResult, isA<Ok<List<Screening>>>());
      expect(
        (screeningsResult as Ok<List<Screening>>).value.every(
          (screening) => screening.movieId == 'm1',
        ),
        isTrue,
      );
    });

    test('creates, updates, fetches, and deletes a reservation', () async {
      final repository = MockCinemaRepository();
      const draft = Reservation(
        id: 'temporary',
        screeningId: 's1',
        userId: 'u2',
        seats: ['H9'],
        totalPrice: 95,
        status: 'Ожидает подтверждения',
      );

      final createResult = await repository.createReservation(draft);
      expect(createResult, isA<Ok<Reservation>>());
      final created = (createResult as Ok<Reservation>).value;
      expect(created.id, 'r1000');

      final updateResult = await repository.updateReservation(
        created.copyWith(status: 'Отменено'),
      );
      expect(updateResult, isA<Ok<Reservation>>());
      expect((updateResult as Ok<Reservation>).value.status, 'Отменено');

      final fetchResult = await repository.fetchReservationById(created.id);
      expect((fetchResult as Ok<Reservation>).value.status, 'Отменено');

      final deleteResult = await repository.deleteReservation(created.id);
      expect(deleteResult, isA<Ok<void>>());
      expect(
        await repository.fetchReservationById(created.id),
        isA<Err<Reservation>>(),
      );
    });

    test('returns an error when a reservation does not exist', () async {
      final repository = MockCinemaRepository();

      expect(
        await repository.fetchReservationById('unknown'),
        isA<Err<Reservation>>(),
      );
      expect(await repository.deleteReservation('unknown'), isA<Err<void>>());
    });

    test('returns Err when mock network failure is enabled', () async {
      final repository = MockCinemaRepository()..simulateError = true;

      final result = await repository.fetchMovies();

      expect(result, isA<Err<List<Movie>>>());
      expect((result as Err<List<Movie>>).msg, contains('Сервер не отвечает'));
    });

    test('simulates network latency', () async {
      final repository = MockCinemaRepository();
      final stopwatch = Stopwatch()..start();

      await repository.fetchMovies();

      expect(
        stopwatch.elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 750)),
      );
    });
  });
}
