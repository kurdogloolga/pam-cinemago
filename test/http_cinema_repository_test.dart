import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cinemago/data/http_cinema_repository.dart';
import 'package:cinemago/data/result.dart';
import 'package:cinemago/data/token_store.dart';
import 'package:cinemago/models/reservation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailingClearTokenStore extends TokenStore {
  @override
  Future<bool> clearIfVersion(int version) async =>
      throw PlatformException(code: 'storage_failed');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TokenStore tokens;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tokens = TokenStore();
    await tokens.save('jwt');
  });

  const reservation = Reservation(
    id: '3',
    screeningId: '2',
    userId: '1',
    seats: ['A1', 'A2'],
    totalPrice: 200,
    status: 'Подтверждено',
  );
  const reservationJson =
      '{"id":3,"screeningId":2,"userId":1,"seats":["A1","A2"],'
      '"totalPrice":200,"status":"Подтверждено"}';

  test('loads and decodes movies, screenings and reservations', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.headers['authorization'], 'Bearer jwt');
      switch (request.url.path) {
        case '/movies':
          return http.Response(
            '{"items":[{"id":1,"title":"Film","genre":"Drama",'
            '"durationMin":120,"posterUrl":"","rating":8}]}',
            200,
          );
        case '/screenings':
          expect(request.url.queryParameters, {'movieId': '1'});
          return http.Response(
            '{"items":[{"id":2,"movieId":1,"hall":"Hall",'
            '"dateTime":"2026-10-10T12:30:00Z","price":100,'
            '"seatsTaken":["A1"]}]}',
            200,
          );
        case '/reservations':
          expect(request.url.query, isEmpty);
          return http.Response(
            '{"items":[$reservationJson]}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        case '/reservations/3':
          return http.Response(
            reservationJson,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        default:
          fail('Unexpected request: ${request.url}');
      }
    });
    final repo = HttpCinemaRepository(
      'http://example.test/',
      tokens,
      client: client,
    );

    final movies = (await repo.fetchMovies() as Ok).value;
    expect(movies.single.id, '1');
    expect(movies.single.rating, 8.0);
    expect(movies.single.year, isNull);
    expect(movies.single.description, isNull);
    final screenings = (await repo.fetchScreenings('1') as Ok).value;
    expect(screenings.single.movieId, '1');
    expect(screenings.single.price, 100.0);
    expect(
      screenings.single.dateTime.toUtc(),
      DateTime.utc(2026, 10, 10, 12, 30),
    );
    expect(screenings.single.seatsTaken, ['A1']);
    final reservations = (await repo.fetchReservations('u1') as Ok).value;
    expect(reservations.single.userId, '1');
    expect(reservations.single.totalPrice, 200.0);
    expect((await repo.fetchReservationById('3') as Ok).value.seats, [
      'A1',
      'A2',
    ]);
    client.close();
  });

  test(
    'creates, updates and deletes reservations using correct payloads',
    () async {
      final client = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer jwt');
        if (request.method == 'DELETE') {
          expect(request.url.path, '/reservations/3');
          return http.Response('', 204);
        }
        expect(jsonDecode(request.body), {
          'screeningId': 2,
          'seats': ['A1', 'A2'],
          'status': request.method == 'POST' ? 'Подтверждено' : 'Отменено',
        });
        if (request.method == 'POST') {
          expect(request.url.path, '/reservations');
          return http.Response(
            reservationJson,
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        expect(request.method, 'PUT');
        expect(request.url.path, '/reservations/3');
        return http.Response(
          reservationJson.replaceAll('Подтверждено', 'Отменено'),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final repo = HttpCinemaRepository(
        'http://example.test',
        tokens,
        client: client,
      );
      expect((await repo.createReservation(reservation) as Ok).value.id, '3');
      expect(
        (await repo.updateReservation(
          reservation.copyWith(status: 'Отменено'),
        ) as Ok).value.status,
        'Отменено',
      );
      expect(await repo.deleteReservation('3'), isA<Ok<void>>());
      client.close();
    },
  );

  test(
    'reports invalid screening identifier without sending a request',
    () async {
      final client = MockClient((_) async => fail('Unexpected request'));
      final repo = HttpCinemaRepository(
        'http://example.test',
        tokens,
        client: client,
      );
      final result = await repo.createReservation(
        reservation.copyWith(screeningId: 's1'),
      );
      expect((result as Err).msg, 'Некорректный идентификатор сеанса');
      client.close();
    },
  );

  test(
    'translates errors and handles invalid JSON or response shapes',
    () async {
      for (final (body, status, message) in [
        ('{"error":{"code":"NOT_FOUND"}}', 404, 'Запись не существует'),
        ('<html>', 200, 'Ответ не тот, что обещан'),
        ('{"items":[{}]}', 200, 'Ответ не тот, что обещан'),
        ('{}', 200, 'Ответ не тот, что обещан'),
      ]) {
        final client = MockClient((_) async => http.Response(body, status));
        final result = await HttpCinemaRepository(
          'http://example.test',
          tokens,
          client: client,
        ).fetchMovies();
        expect((result as Err).msg, message);
        client.close();
      }
    },
  );

  test('clears token and calls callback on 401', () async {
    var called = false;
    final client = MockClient((_) async => http.Response('', 401));
    final repo = HttpCinemaRepository(
      'http://example.test',
      tokens,
      client: client,
      onUnauthorized: () => called = true,
    );
    final result = await repo.fetchMovies();
    expect((result as Err).msg, 'Сессия истекла — войдите снова');
    expect(await tokens.read(), isNull);
    expect(called, isTrue);
    client.close();
  });

  test('reports token removal failure without calling callback', () async {
    var called = false;
    final client = MockClient((_) async => http.Response('', 401));
    final result = await HttpCinemaRepository(
      'http://example.test',
      FailingClearTokenStore(),
      client: client,
      onUnauthorized: () => called = true,
    ).fetchMovies();
    expect((result as Err).msg, 'Не удалось получить или удалить токен');
    expect(called, isFalse);
    client.close();
  });

  test('reports network errors and timeouts', () async {
    for (final error in [
      const SocketException('network unavailable'),
      http.ClientException('network unavailable'),
    ]) {
      final client = MockClient((_) async => throw error);
      final result = await HttpCinemaRepository(
        'http://example.test',
        tokens,
        client: client,
      ).fetchMovies();
      expect((result as Err).msg, 'Нет сети — повторите попытку');
      client.close();
    }
    final client = MockClient((_) => Completer<http.Response>().future);
    final result = await HttpCinemaRepository(
      'http://example.test',
      tokens,
      client: client,
      timeout: const Duration(milliseconds: 1),
    ).fetchMovies();
    expect((result as Err).msg, 'Сервер не отвечает');
    client.close();
  });
}
