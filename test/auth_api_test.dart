import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cinemago/data/auth_api.dart';
import 'package:cinemago/data/result.dart';
import 'package:cinemago/data/token_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailingTokenStore extends TokenStore {
  @override
  Future<void> save(String token) async {
    throw PlatformException(code: 'storage_failed');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TokenStore tokens;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tokens = TokenStore();
  });

  test('register sends credentials and stores the token', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://example.test/auth/register');
      expect(request.method, 'POST');
      expect(request.headers['content-type'], 'application/json');
      expect(jsonDecode(request.body), {
        'email': 'user@example.test',
        'password': 'password123',
        'name': 'User',
      });
      return http.Response('{"token":"register-token"}', 201);
    });
    final api = AuthApi('http://example.test/', tokens, client: client);

    final result = await api.register(
      'user@example.test',
      'password123',
      'User',
    );

    expect(result, isA<Ok<void>>());
    expect(await tokens.read(), 'register-token');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getKeys(), {'auth_token'});
    client.close();
  });

  test('login saves token and logout removes it', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/auth/login');
      expect(jsonDecode(request.body), {
        'email': 'user@example.test',
        'password': 'password123',
      });
      return http.Response('{"token":"login-token"}', 200);
    });
    final api = AuthApi('http://example.test', tokens, client: client);

    expect(
      await api.login('user@example.test', 'password123'),
      isA<Ok<void>>(),
    );
    expect(await TokenStore().read(), 'login-token');
    await api.logout();
    expect(await tokens.read(), isNull);
    client.close();
  });

  test('translates HTTP errors and does not store a token', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"error":{"code":"EMAIL_TAKEN","message":"ignored"}}',
        409,
      ),
    );
    final result = await AuthApi(
      'http://example.test',
      tokens,
      client: client,
    ).register('user@example.test', 'password123', 'User');

    expect(result, isA<Err<void>>());
    expect((result as Err<void>).msg, 'Аккаунт с этим email уже существует');
    expect(await tokens.read(), isNull);
    client.close();
  });

  test('reports invalid successful responses without saving a token', () async {
    for (final body in ['<html>', '{}', '{"token":4}', '{"token":""}']) {
      final client = MockClient((_) async => http.Response(body, 200));
      final result = await AuthApi(
        'http://example.test',
        tokens,
        client: client,
      ).login('user@example.test', 'password123');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).msg, 'Ответ не тот, что обещан');
      expect(await tokens.read(), isNull);
      client.close();
    }
  });

  test('reports network errors from native and browser HTTP clients', () async {
    for (final error in [
      const SocketException('network unavailable'),
      http.ClientException('network unavailable'),
    ]) {
      final client = MockClient((_) async => throw error);
      final result = await AuthApi(
        'http://example.test',
        tokens,
        client: client,
      ).login('user@example.test', 'password123');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).msg, 'Нет сети — повторите попытку');
      client.close();
    }
  });

  test('reports a timeout', () async {
    final client = MockClient((_) => Completer<http.Response>().future);
    final result = await AuthApi(
      'http://example.test',
      tokens,
      client: client,
      timeout: const Duration(milliseconds: 1),
    ).login('user@example.test', 'password123');

    expect(result, isA<Err<void>>());
    expect((result as Err<void>).msg, 'Сервер не отвечает');
    client.close();
  });

  test('reports failure to save a token', () async {
    final client = MockClient(
      (_) async => http.Response('{"token":"login-token"}', 200),
    );
    final result = await AuthApi(
      'http://example.test',
      FailingTokenStore(),
      client: client,
    ).login('user@example.test', 'password123');

    expect(result, isA<Err<void>>());
    expect((result as Err<void>).msg, 'Не удалось сохранить токен');
    client.close();
  });
}
