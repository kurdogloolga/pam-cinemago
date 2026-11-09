import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/user_profile.dart';
import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';

class AuthApi {
  factory AuthApi(
    String baseUrl,
    TokenStore tokens, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 8),
    void Function()? onUnauthorized,
  }) => AuthApi._(
    baseUrl.replaceFirst(RegExp(r'/+$'), ''),
    tokens,
    client,
    timeout,
    onUnauthorized,
  );

  AuthApi._(
    this._baseUrl,
    this.tokens,
    this._client,
    this._timeout,
    this.onUnauthorized,
  );

  final String _baseUrl;
  final TokenStore tokens;
  final http.Client? _client;
  final Duration _timeout;
  final void Function()? onUnauthorized;

  Future<Result<void>> register(String email, String password, String name) =>
      _post('/auth/register', {
        'email': email,
        'password': password,
        'name': name,
      });

  Future<Result<void>> login(String email, String password) =>
      _post('/auth/login', {'email': email, 'password': password});

  Future<void> logout() => tokens.clear();

  Future<Result<UserProfile>> fetchProfile() async {
    final client = _client ?? http.Client();
    try {
      final tokenVersion = tokens.version;
      final token = await tokens.read();
      final response = await client
          .get(
            Uri.parse('$_baseUrl/me'),
            headers: {'Authorization': 'Bearer ${token ?? ''}'},
          )
          .timeout(_timeout);
      if (response.statusCode == 401) {
        final cleared = await tokens.clearIfVersion(tokenVersion);
        if (cleared && tokens.version == tokenVersion + 1) {
          onUnauthorized?.call();
        }
        return const Err('Сессия истекла — войдите снова');
      }
      if (tokens.version != tokenVersion) {
        return const Err('Сессия изменилась — повторите попытку');
      }
      if (response.statusCode != 200) return Err(apiMessage(response));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Ok(UserProfile.fromJson(data));
    } on SocketException {
      return const Err('Нет сети — повторите попытку');
    } on http.ClientException {
      return const Err('Нет сети — повторите попытку');
    } on TimeoutException {
      return const Err('Сервер не отвечает');
    } on FormatException {
      return const Err('Ответ не тот, что обещан');
    } on TypeError {
      return const Err('Ответ не тот, что обещан');
    } on StateError {
      return const Err('Не удалось получить или удалить токен');
    } on PlatformException {
      return const Err('Не удалось получить или удалить токен');
    } finally {
      if (_client == null) client.close();
    }
  }

  Future<Result<void>> _post(String path, Map<String, Object?> body) async {
    final client = _client ?? http.Client();
    try {
      final response = await client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        return Err(apiMessage(response));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String;
      if (token.trim().isEmpty) {
        return const Err('Ответ не тот, что обещан');
      }

      try {
        await tokens.save(token);
      } on StateError {
        return const Err('Не удалось сохранить токен');
      } on PlatformException {
        return const Err('Не удалось сохранить токен');
      }
      return const Ok(null);
    } on SocketException {
      return const Err('Нет сети — повторите попытку');
    } on http.ClientException {
      return const Err('Нет сети — повторите попытку');
    } on TimeoutException {
      return const Err('Сервер не отвечает');
    } on FormatException {
      return const Err('Ответ не тот, что обещан');
    } on TypeError {
      return const Err('Ответ не тот, что обещан');
    } finally {
      if (_client == null) client.close();
    }
  }
}
