import 'dart:async';
import 'dart:io';

import 'package:cinemago/data/file_api.dart';
import 'package:cinemago/data/result.dart';
import 'package:cinemago/data/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TokenStore tokens;
  late Directory tempDir;
  late String imagePath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tokens = TokenStore();
    tempDir = await Directory.systemTemp.createTemp('cinemago-file-api-');
    imagePath = '${tempDir.path}${Platform.pathSeparator}poster.png';
    await File(imagePath).writeAsBytes([1, 2, 3]);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test(
    'uploads a multipart file with Bearer token and returns its URL',
    () async {
      await tokens.save('test-token');
      final client = MockClient((request) async {
        expect(request.url.toString(), 'http://example.test/files');
        expect(request.method, 'POST');
        expect(request.headers['authorization'], 'Bearer test-token');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data;'),
        );
        expect(request.body, contains('name="file"'));
        expect(request.body, contains('poster.png'));
        return http.Response('{"id":7,"url":"/files/7"}', 201);
      });

      final result = await FileApi(
        'http://example.test/',
        tokens,
        client: client,
      ).upload(imagePath);

      expect(result, isA<Ok<String>>());
      expect((result as Ok<String>).value, '/files/7');
      client.close();
    },
  );

  test('reports invalid successful upload responses', () async {
    await tokens.save('test-token');
    for (final body in ['<html>', '{}', '{"url":4}', '{"url":"other"}']) {
      final client = MockClient((_) async => http.Response(body, 201));
      final result = await FileApi(
        'http://example.test',
        tokens,
        client: client,
      ).upload(imagePath);

      expect(result, isA<Err<String>>());
      expect((result as Err<String>).msg, 'Ответ не тот, что обещан');
      client.close();
    }
  });

  test('translates server errors', () async {
    await tokens.save('test-token');
    final client = MockClient(
      (_) async => http.Response(
        '{"error":{"code":"VALIDATION_ERROR","message":"ignored"}}',
        400,
      ),
    );

    final result = await FileApi(
      'http://example.test',
      tokens,
      client: client,
    ).upload(imagePath);

    expect(result, isA<Err<String>>());
    expect((result as Err<String>).msg, 'Отправленные данные недействительны');
    client.close();
  });

  test('reports network errors and timeouts', () async {
    await tokens.save('test-token');
    for (final error in [
      const SocketException('network unavailable'),
      http.ClientException('network unavailable'),
    ]) {
      final client = MockClient((_) async => throw error);
      final result = await FileApi(
        'http://example.test',
        tokens,
        client: client,
      ).upload(imagePath);

      expect(result, isA<Err<String>>());
      expect((result as Err<String>).msg, 'Нет сети — повторите попытку');
      client.close();
    }

    final client = MockClient((_) => Completer<http.Response>().future);
    final result = await FileApi(
      'http://example.test',
      tokens,
      client: client,
      timeout: const Duration(milliseconds: 1),
    ).upload(imagePath);

    expect(result, isA<Err<String>>());
    expect((result as Err<String>).msg, 'Сервер не отвечает');
    client.close();
  });

  test('clears an expired token and notifies the session handler', () async {
    await tokens.save('expired-token');
    var unauthorizedCalls = 0;
    final client = MockClient((_) async => http.Response('{}', 401));

    final result = await FileApi(
      'http://example.test',
      tokens,
      client: client,
      onUnauthorized: () => unauthorizedCalls++,
    ).upload(imagePath);

    expect(result, isA<Err<String>>());
    expect((result as Err<String>).msg, 'Сессия истекла — войдите снова');
    expect(await tokens.read(), isNull);
    expect(unauthorizedCalls, 1);
    client.close();
  });

  test('reports a missing local file', () async {
    await tokens.save('test-token');
    final client = MockClient((_) async => http.Response('{}', 201));

    final result = await FileApi(
      'http://example.test',
      tokens,
      client: client,
    ).upload('${tempDir.path}${Platform.pathSeparator}missing.png');

    expect(result, isA<Err<String>>());
    expect((result as Err<String>).msg, 'Не удалось прочитать файл');
    client.close();
  });
}
