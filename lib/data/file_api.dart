import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';

class FileApi {
  FileApi(
    String baseUrl,
    this._tokens, {
    this.onUnauthorized,
    this.client,
    this.timeout = const Duration(seconds: 20),
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');

  final String _baseUrl;
  final TokenStore _tokens;
  final void Function()? onUnauthorized;
  final http.Client? client;
  final Duration timeout;

  Future<Result<String>> upload(String path) async {
    final requestClient = client ?? http.Client();
    try {
      final tokenVersion = _tokens.version;
      final token = await _tokens.read();
      final request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl/files'))
            ..headers['Authorization'] = 'Bearer ${token ?? ''}'
            ..files.add(await http.MultipartFile.fromPath('file', path));
      final response = await requestClient
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);

      if (response.statusCode == 401) {
        final cleared = await _tokens.clearIfVersion(tokenVersion);
        if (cleared && _tokens.version == tokenVersion + 1) {
          onUnauthorized?.call();
        }
        return const Err('Сессия истекла — войдите снова');
      }
      if (response.statusCode != 201) return Err(apiMessage(response));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['url'] as String;
      if (!url.startsWith('/files/') || url.length <= '/files/'.length) {
        return const Err('Ответ не тот, что обещан');
      }
      return Ok(url);
    } on SocketException {
      return const Err('Нет сети — повторите попытку');
    } on http.ClientException {
      return const Err('Нет сети — повторите попытку');
    } on TimeoutException {
      return const Err('Сервер не отвечает');
    } on FileSystemException {
      return const Err('Не удалось прочитать файл');
    } on FormatException {
      return const Err('Ответ не тот, что обещан');
    } on TypeError {
      return const Err('Ответ не тот, что обещан');
    } on StateError {
      return const Err('Не удалось получить или удалить токен');
    } on PlatformException {
      return const Err('Не удалось получить или удалить токен');
    } finally {
      if (client == null) requestClient.close();
    }
  }
}
