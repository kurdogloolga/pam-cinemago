import 'dart:convert';

import 'package:http/http.dart' as http;

String apiMessage(http.Response response) {
  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final error = body['error'] as Map<String, dynamic>;
    final code = error['code'] as String;

    return switch (code) {
      'VALIDATION_ERROR' => 'Отправленные данные недействительны',
      'UNAUTHORIZED' => 'Неверный email или пароль',
      'EMAIL_TAKEN' => 'Аккаунт с этим email уже существует',
      'NOT_FOUND' => 'Запись не существует',
      _ => 'Ошибка сервера ($code)',
    };
  } on FormatException {
    return 'Ошибка сервера (${response.statusCode})';
  } on TypeError {
    return 'Ошибка сервера (${response.statusCode})';
  }
}
