import 'dart:async';
import 'dart:convert';

import 'package:cinemago/data/auth_api.dart';
import 'package:cinemago/data/http_cinema_repository.dart';
import 'package:cinemago/data/token_store.dart';
import 'package:cinemago/main.dart';
import 'package:cinemago/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('loads after login and isolates state between accounts', (
    tester,
  ) async {
    final tokens = TokenStore();
    var protectedRequests = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/auth/login') {
        final email =
            (jsonDecode(request.body) as Map<String, dynamic>)['email'];
        return http.Response(jsonEncode({'token': email}), 200);
      }
      protectedRequests++;
      final token = request.headers['authorization'];
      if (request.url.path == '/movies') {
        return http.Response(
          '{"items":[{"id":1,"title":"Film","genre":"Drama",'
          '"durationMin":120,"posterUrl":"","rating":8}]}',
          200,
        );
      }
      if (request.url.path == '/reservations') {
        return http.Response(
          token == 'Bearer a@example.test'
              ? '{"items":[{"id":1,"screeningId":1,"userId":1,'
                    '"seats":["A1"],"totalPrice":100,"status":"confirmed"}]}'
              : '{"items":[]}',
          200,
        );
      }
      return http.Response('{"items":[]}', 200);
    });
    late final GoRouter router;
    router = createAppRouter(
      repository: HttpCinemaRepository(
        'http://example.test',
        tokens,
        client: client,
        onUnauthorized: () => router.go('/login'),
      ),
    );
    await tester.pumpWidget(
      MyApp(
        auth: AuthApi('http://example.test', tokens, client: client),
        router: router,
      ),
    );
    await tester.pumpAndSettle();
    expect(protectedRequests, 0);

    Future<void> login(String email) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Электронная почта'),
        email,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Пароль'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
      await tester.pumpAndSettle();
    }

    await login('a@example.test');
    expect(find.text('Film'), findsOneWidget);
    expect(
      tester
          .widget<Badge>(find.byKey(const ValueKey('tickets-badge')))
          .isLabelVisible,
      isTrue,
    );
    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Выйти из аккаунта'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Выйти из аккаунта'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Да, выйти'));
    await tester.pumpAndSettle();
    expect(await tokens.read(), isNull);
    await login('b@example.test');
    expect(find.text('Film'), findsOneWidget);
    expect(
      tester
          .widget<Badge>(find.byKey(const ValueKey('tickets-badge')))
          .isLabelVisible,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    client.close();
  });

  testWidgets('expired token clears and routes to login on parallel 401s', (
    tester,
  ) async {
    final tokens = TokenStore();
    await tokens.save('expired');
    final client = MockClient((_) async => http.Response('', 401));
    var redirects = 0;
    late final GoRouter router;
    router = createAppRouter(
      loggedIn: true,
      repository: HttpCinemaRepository(
        'http://example.test',
        tokens,
        client: client,
        onUnauthorized: () {
          redirects++;
          router.go('/login');
        },
      ),
    );
    await tester.pumpWidget(
      MyApp(
        auth: AuthApi('http://example.test', tokens, client: client),
        router: router,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Вход / регистрация'), findsOneWidget);
    expect(await tokens.read(), isNull);
    expect(redirects, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    client.close();
  });

  test('a late 401 cannot clear a newer session', () async {
    final tokens = TokenStore();
    await tokens.save('old');
    final pending = Completer<http.Response>();
    final requested = Completer<void>();
    final client = MockClient((_) {
      requested.complete();
      return pending.future;
    });
    var redirected = false;
    final repo = HttpCinemaRepository(
      'http://example.test',
      tokens,
      client: client,
      onUnauthorized: () => redirected = true,
    );
    final request = repo.fetchMovies();
    await requested.future;
    await tokens.save('new');
    pending.complete(http.Response('', 401));
    await request;
    expect(await tokens.read(), 'new');
    expect(redirected, isFalse);
    client.close();
  });
}
