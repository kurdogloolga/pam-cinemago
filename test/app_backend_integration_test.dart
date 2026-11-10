import 'dart:convert';
import 'dart:io';

import 'package:cinemago/data/auth_api.dart';
import 'package:cinemago/data/http_cinema_repository.dart';
import 'package:cinemago/data/token_store.dart';
import 'package:cinemago/main.dart';
import 'package:cinemago/router.dart';
import 'package:cinemago/widgets/movie_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const baseUrl = String.fromEnvironment('AUTH_TEST_BASE_URL');

  testWidgets('application books and cancels a seat using the real backend', (
    tester,
  ) async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);
    SharedPreferences.setMockInitialValues({});
    final tokens = TokenStore();
    late int movieId;
    late int screeningId;
    late String token;
    await tester.runAsync(() async {
      final email =
          'ui-test-${DateTime.now().microsecondsSinceEpoch}@example.test';
      final registration = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': 'password123',
          'name': 'Test',
        }),
      );
      expect(registration.statusCode, 201);
      token =
          (jsonDecode(registration.body) as Map<String, dynamic>)['token']
              as String;
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final movie = await http.post(
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
      expect(movie.statusCode, 201);
      movieId = (jsonDecode(movie.body) as Map<String, dynamic>)['id'] as int;
      final screening = await http.post(
        Uri.parse('$baseUrl/screenings'),
        headers: headers,
        body: jsonEncode({
          'movieId': movieId,
          'hall': 'Test hall',
          'dateTime': '2027-10-10T12:30:00Z',
          'price': 100,
        }),
      );
      expect(screening.statusCode, 201);
      screeningId =
          (jsonDecode(screening.body) as Map<String, dynamic>)['id'] as int;
    });
    await tokens.save(token);

    late final GoRouter router;
    router = createAppRouter(
      loggedIn: true,
      repository: HttpCinemaRepository(
        baseUrl,
        tokens,
        onUnauthorized: () => router.go('/login'),
      ),
    );
    await tester.pumpWidget(
      MyApp(auth: AuthApi(baseUrl, tokens), router: router),
    );

    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(finder, findsWidgets);
    }

    await waitFor(find.text('Test film'));
    await tester.tap(find.byType(MovieCard).first);
    await tester.pump(const Duration(milliseconds: 350));
    await waitFor(find.text('Выбрать сеанс'));
    await waitFor(find.text('Test hall'));
    await tester.tap(find.text('Выбрать сеанс'));
    await tester.pump(const Duration(milliseconds: 350));
    await waitFor(find.text('Test hall'));
    await tester.tap(find.text('Продолжить'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await waitFor(find.byKey(const ValueKey('seat-A1')));
    await tester.ensureVisible(find.byKey(const ValueKey('seat-A1')));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const ValueKey('seat-A1')));
    await tester.pump();
    await waitFor(find.text('Продолжить · 100 MDL'));
    await tester.tap(find.text('Продолжить · 100 MDL'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Подтвердить бронирование'));
    await waitFor(find.text('Бронирование подтверждено'));
    await waitFor(find.text('Места A1'));
    await tester.runAsync(() async {
      final response = await http.get(
        Uri.parse('$baseUrl/screenings/$screeningId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      expect(
        (jsonDecode(response.body) as Map<String, dynamic>)['seatsTaken'],
        ['A1'],
      );
    });
    await tester.scrollUntilVisible(
      find.text('Отменить бронь'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Отменить бронь'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.widgetWithText(FilledButton, 'Отменить'));
    await waitFor(find.text('Бронирование отменено'));
    await tester.runAsync(() async {
      final response = await http.get(
        Uri.parse('$baseUrl/screenings/$screeningId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      expect(
        (jsonDecode(response.body) as Map<String, dynamic>)['seatsTaken'],
        isEmpty,
      );
    });
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  }, skip: baseUrl.isEmpty);
}
