import 'dart:convert';
import 'dart:io';

import 'package:cinemago/data/auth_api.dart';
import 'package:cinemago/data/file_api.dart';
import 'package:cinemago/data/http_cinema_repository.dart';
import 'package:cinemago/data/result.dart';
import 'package:cinemago/data/token_store.dart';
import 'package:cinemago/models/movie.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const baseUrl = String.fromEnvironment('AUTH_TEST_BASE_URL');

  test('uploads poster, saves it on a movie and downloads the image', () async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);
    SharedPreferences.setMockInitialValues({});
    final tokens = TokenStore();
    final email =
        'poster-test-${DateTime.now().microsecondsSinceEpoch}@example.test';
    final authResult = await AuthApi(
      baseUrl,
      tokens,
    ).register(email, 'password123', 'Poster test');
    expect(authResult, isA<Ok<void>>());

    final headers = {
      'Authorization': 'Bearer ${await tokens.read()}',
      'Content-Type': 'application/json',
    };
    final createMovie = await http.post(
      Uri.parse('$baseUrl/movies'),
      headers: headers,
      body: jsonEncode({
        'title': 'Poster test movie',
        'genre': 'Drama',
        'durationMin': 100,
        'posterUrl': '',
        'rating': 7,
      }),
    );
    expect(createMovie.statusCode, 201);
    final movieId =
        (jsonDecode(createMovie.body) as Map<String, dynamic>)['id'] as int;

    final tempDir = await Directory.systemTemp.createTemp(
      'cinemago-poster-integration-',
    );
    addTearDown(() => tempDir.delete(recursive: true));
    final imageBytes = [137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3, 4];
    final imageFile = File(
      '${tempDir.path}${Platform.pathSeparator}poster.png',
    );
    await imageFile.writeAsBytes(imageBytes);
    final uploaded = await FileApi(baseUrl, tokens).upload(imageFile.path);
    expect(uploaded, isA<Ok<String>>());
    final posterUrl = (uploaded as Ok<String>).value;

    final updateMovie = await http.put(
      Uri.parse('$baseUrl/movies/$movieId'),
      headers: headers,
      body: jsonEncode({
        'title': 'Poster test movie',
        'genre': 'Drama',
        'durationMin': 100,
        'posterUrl': posterUrl,
        'rating': 7,
      }),
    );
    expect(updateMovie.statusCode, 200);

    final movies = await HttpCinemaRepository(baseUrl, tokens).fetchMovies();
    expect(movies, isA<Ok<List<Movie>>>());
    final movie = (movies as Ok<List<Movie>>).value.singleWhere(
      (movie) => movie.id == movieId.toString(),
    );
    expect(movie.posterUrl, posterUrl);

    final downloaded = await http.get(Uri.parse('$baseUrl$posterUrl'));
    expect(downloaded.statusCode, 200);
    expect(downloaded.bodyBytes, imageBytes);
  }, skip: baseUrl.isEmpty);
}
