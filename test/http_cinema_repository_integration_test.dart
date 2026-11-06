import 'dart:convert';
import 'dart:io';

import 'package:cinemago/data/auth_api.dart';
import 'package:cinemago/data/http_cinema_repository.dart';
import 'package:cinemago/data/result.dart';
import 'package:cinemago/data/token_store.dart';
import 'package:cinemago/models/reservation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const baseUrl = String.fromEnvironment('AUTH_TEST_BASE_URL');

  test(
    'uses the real backend for cinema queries and reservation lifecycle',
    () async {
      final previousOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousOverrides);
      SharedPreferences.setMockInitialValues({});
      final tokens = TokenStore();
      final auth = AuthApi(baseUrl, tokens);
      final email =
          'cinema-test-${DateTime.now().microsecondsSinceEpoch}@example.test';
      expect(
        await auth.register(email, 'password123', 'CinemaGo'),
        isA<Ok<void>>(),
      );
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await tokens.read()}',
      };
      final movieResponse = await http.post(
        Uri.parse('$baseUrl/movies'),
        headers: headers,
        body: jsonEncode({
          'title': 'Test film',
          'genre': 'Drama',
          'durationMin': 120,
          'posterUrl': '',
          'rating': 8,
        }),
      );
      expect(movieResponse.statusCode, 201);
      final movieId =
          (jsonDecode(movieResponse.body) as Map<String, dynamic>)['id'] as int;
      final screeningResponse = await http.post(
        Uri.parse('$baseUrl/screenings'),
        headers: headers,
        body: jsonEncode({
          'movieId': movieId,
          'hall': 'Test hall',
          'dateTime': '2026-10-10T12:30:00Z',
          'price': 100,
        }),
      );
      expect(screeningResponse.statusCode, 201);
      final screeningId =
          (jsonDecode(screeningResponse.body) as Map<String, dynamic>)['id']
              as int;
      var unauthorized = false;
      final repo = HttpCinemaRepository(
        baseUrl,
        tokens,
        onUnauthorized: () => unauthorized = true,
      );

      final movies = (await repo.fetchMovies() as Ok).value;
      expect(movies.single.title, 'Test film');
      final screenings = (await repo.fetchScreenings('$movieId') as Ok).value;
      expect(screenings.single.seatsTaken, isEmpty);
      final created = (await repo.createReservation(
        Reservation(
          id: '',
          screeningId: '$screeningId',
          userId: 'u1',
          seats: const ['A1', 'A2'],
          totalPrice: 1,
          status: 'Подтверждено',
        ),
      ) as Ok).value;
      expect(created.id, isNotEmpty);
      expect(created.userId, isNot('u1'));
      expect(created.totalPrice, 200);
      expect((await repo.fetchReservationById(created.id) as Ok).value.seats, [
        'A1',
        'A2',
      ]);
      expect((await repo.fetchReservations('u1') as Ok).value.length, 1);
      expect(
        (await repo.fetchScreenings('$movieId') as Ok).value.single.seatsTaken,
        ['A1', 'A2'],
      );
      final updated = (await repo.updateReservation(
        created.copyWith(status: 'Отменено'),
      ) as Ok).value;
      expect(updated.status, 'Отменено');
      expect(
        (await repo.fetchScreenings('$movieId') as Ok).value.single.seatsTaken,
        isEmpty,
      );
      expect(await repo.deleteReservation(created.id), isA<Ok<void>>());
      expect(
        await repo.fetchReservationById(created.id),
        isA<Err<Reservation>>(),
      );
      await tokens.save('invalid-token');
      expect(await repo.fetchMovies(), isA<Err>());
      expect(await tokens.read(), isNull);
      expect(unauthorized, isTrue);
    },
    skip: baseUrl.isEmpty
        ? 'Set AUTH_TEST_BASE_URL to run against an isolated backend.'
        : false,
  );
}
