import 'dart:async';
import 'dart:io';

import 'package:cinemago/data/auth_api.dart';
import 'package:cinemago/data/result.dart';
import 'package:cinemago/data/token_store.dart';
import 'package:cinemago/models/user_profile.dart';
import 'package:cinemago/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TokenStore tokens;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tokens = TokenStore();
  });

  test('requests the current profile using the saved token', () async {
    await tokens.save('test-token');
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://example.test/me');
      expect(request.method, 'GET');
      expect(request.headers['authorization'], 'Bearer test-token');
      return http.Response(
        '{"id":5,"name":"Olga","email":"olga@example.test"}',
        200,
      );
    });
    final result = await AuthApi(
      'http://example.test/',
      tokens,
      client: client,
    ).fetchProfile();
    expect(result, isA<Ok<UserProfile>>());
    final profile = (result as Ok<UserProfile>).value;
    expect(profile.id, 5);
    expect(profile.name, 'Olga');
    expect(profile.email, 'olga@example.test');
    client.close();
  });

  test('rejects invalid responses and reports network errors', () async {
    for (final body in [
      '<html>',
      '{}',
      '{"id":1,"name":"","email":"x@example.test"}',
      '{"id":1,"name":"User","email":42}',
    ]) {
      final client = MockClient((_) async => http.Response(body, 200));
      final result = await AuthApi(
        'http://example.test',
        tokens,
        client: client,
      ).fetchProfile();
      expect((result as Err<UserProfile>).msg, 'Ответ не тот, что обещан');
      client.close();
    }
    final client = MockClient((_) async => throw const SocketException('down'));
    final result = await AuthApi(
      'http://example.test',
      tokens,
      client: client,
    ).fetchProfile();
    expect((result as Err<UserProfile>).msg, 'Нет сети — повторите попытку');
    client.close();
  });

  test('expired session clears the token and notifies the router', () async {
    await tokens.save('expired');
    var redirects = 0;
    final client = MockClient((_) async => http.Response('', 401));
    final result = await AuthApi(
      'http://example.test',
      tokens,
      client: client,
      onUnauthorized: () => redirects++,
    ).fetchProfile();
    expect((result as Err<UserProfile>).msg, 'Сессия истекла — войдите снова');
    expect(await tokens.read(), isNull);
    expect(redirects, 1);
    client.close();
  });

  test(
    'late profile responses cannot overwrite or clear a newer session',
    () async {
      for (final status in [200, 401]) {
        await tokens.save('old');
        final requested = Completer<void>();
        final pending = Completer<http.Response>();
        var redirects = 0;
        final client = MockClient((_) {
          requested.complete();
          return pending.future;
        });
        final request = AuthApi(
          'http://example.test',
          tokens,
          client: client,
          onUnauthorized: () => redirects++,
        ).fetchProfile();
        await requested.future;
        await tokens.save('new');
        pending.complete(
          http.Response(
            '{"id":1,"name":"Old","email":"old@example.test"}',
            status,
          ),
        );
        expect(await request, isA<Err<UserProfile>>());
        expect(await tokens.read(), 'new');
        expect(redirects, 0);
        client.close();
      }
    },
  );

  testWidgets('profile shows an error and retries loading', (tester) async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      if (requests == 1) throw const SocketException('down');
      return http.Response(
        '{"id":1,"name":"Olga","email":"olga@example.test"}',
        200,
      );
    });
    await tester.pumpWidget(
      Provider<AuthApi>.value(
        value: AuthApi('http://example.test', tokens, client: client),
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Нет сети — повторите попытку'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Olga'), findsOneWidget);
    expect(find.text('olga@example.test'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Выйти из аккаунта'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Выйти из аккаунта'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    client.close();
  });
}
