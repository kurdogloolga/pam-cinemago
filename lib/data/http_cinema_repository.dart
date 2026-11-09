import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/movie.dart';
import '../models/reservation.dart';
import '../models/screening.dart';
import 'api_message.dart';
import 'cinema_repository.dart';
import 'result.dart';
import 'token_store.dart';

class HttpCinemaRepository implements CinemaRepository {
  HttpCinemaRepository(
    String baseUrl,
    this._tokens, {
    this.onUnauthorized,
    this.client,
    this.timeout = const Duration(seconds: 8),
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');

  final String _baseUrl;
  final TokenStore _tokens;
  final void Function()? onUnauthorized;
  final http.Client? client;
  final Duration timeout;

  @override
  Future<Result<List<Movie>>> fetchMovies({
    int page = 1,
    int limit = 20,
    String? search,
  }) => _list(
    '/movies',
    Movie.fromJson,
    page: page,
    limit: limit,
    search: search,
  );

  @override
  Future<Result<List<Screening>>> fetchScreenings(
    String movieId, {
    int page = 1,
    int limit = 20,
    String? search,
  }) => _list(
    '/screenings',
    Screening.fromJson,
    page: page,
    limit: limit,
    search: search,
    queryParameters: {'movieId': movieId},
  );

  @override
  Future<Result<List<Reservation>>> fetchReservations(
    String userId, {
    int page = 1,
    int limit = 20,
    String? search,
  }) => _list(
    '/reservations',
    Reservation.fromJson,
    page: page,
    limit: limit,
    search: search,
  );

  @override
  Future<Result<Reservation>> fetchReservationById(String id) => _request(
    'GET',
    '/reservations/${Uri.encodeComponent(id)}',
    200,
    (response) =>
        Reservation.fromJson(jsonDecode(response.body) as Map<String, dynamic>),
  );

  @override
  Future<Result<Reservation>> createReservation(Reservation reservation) =>
      _saveReservation('POST', '/reservations', 201, reservation);

  @override
  Future<Result<Reservation>> updateReservation(Reservation reservation) =>
      _saveReservation(
        'PUT',
        '/reservations/${Uri.encodeComponent(reservation.id)}',
        200,
        reservation,
      );

  @override
  Future<Result<void>> deleteReservation(String id) => _request(
    'DELETE',
    '/reservations/${Uri.encodeComponent(id)}',
    204,
    (_) {},
  );

  Future<Result<List<T>>> _list<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    int page = 1,
    int limit = 20,
    String? search,
    Map<String, String>? queryParameters,
  }) {
    final parameters = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (search != null && search.isNotEmpty) 'search': search,
      ...?queryParameters,
    };
    final query = Uri(queryParameters: parameters).query;
    return _request('GET', '$path?$query', 200, (response) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return List<T>.unmodifiable(
        (data['items'] as List).map(
          (item) => parse(item as Map<String, dynamic>),
        ),
      );
    });
  }

  Future<Result<Reservation>> _saveReservation(
    String method,
    String path,
    int status,
    Reservation reservation,
  ) {
    if (int.tryParse(reservation.screeningId) == null) {
      return Future.value(const Err('Некорректный идентификатор сеанса'));
    }
    return _request(
      method,
      path,
      status,
      (response) => Reservation.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      ),
      body: reservation.toJson(),
    );
  }

  Future<Result<T>> _request<T>(
    String method,
    String path,
    int successStatus,
    T Function(http.Response) parse, {
    Map<String, Object>? body,
  }) async {
    final requestClient = client ?? http.Client();
    try {
      final tokenVersion = _tokens.version;
      final token = await _tokens.read();
      final request = http.Request(method, Uri.parse('$_baseUrl$path'));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token ?? ''}',
      });
      if (body != null) request.body = jsonEncode(body);
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
      if (response.statusCode != successStatus) {
        return Err(apiMessage(response));
      }
      return Ok(parse(response));
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
      if (client == null) requestClient.close();
    }
  }
}
