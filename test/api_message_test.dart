import 'dart:convert';

import 'package:cinemago/data/api_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  http.Response errorResponse(String code, int statusCode) {
    return http.Response(
      jsonEncode({
        'error': {'code': code, 'message': 'Server message in English'},
      }),
      statusCode,
    );
  }

  test('translates known error codes without displaying server messages', () {
    final cases = {
      'VALIDATION_ERROR': 'Отправленные данные недействительны',
      'UNAUTHORIZED': 'Неверный email или пароль',
      'EMAIL_TAKEN': 'Аккаунт с этим email уже существует',
      'NOT_FOUND': 'Запись не существует',
      'SEAT_UNAVAILABLE': 'Одно или несколько мест уже заняты',
    };

    for (final entry in cases.entries) {
      expect(apiMessage(errorResponse(entry.key, 400)), entry.value);
    }
  });

  test('reports an unknown code', () {
    expect(
      apiMessage(errorResponse('UNKNOWN', 409)),
      'Ошибка сервера (UNKNOWN)',
    );
  });

  test('uses the HTTP status when the response is not valid JSON', () {
    expect(
      apiMessage(http.Response('<html>Server error</html>', 500)),
      'Ошибка сервера (500)',
    );
  });

  test('uses the HTTP status when the error envelope has the wrong shape', () {
    for (final body in [
      'null',
      '[]',
      '{}',
      '{"error":null}',
      '{"error":{"code":42}}',
    ]) {
      expect(apiMessage(http.Response(body, 503)), 'Ошибка сервера (503)');
    }
  });
}
