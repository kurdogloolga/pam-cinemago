import 'package:cinemago/data/http_cinema_repository.dart';
import 'package:cinemago/data/token_store.dart';
import 'package:cinemago/models/cinema_model.dart';
import 'package:cinemago/screens/movie_detail_screen.dart';
import 'package:cinemago/widgets/movie_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'movie without server details is displayed without invented data',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final client = MockClient((request) async {
        if (request.url.path == '/movies') {
          return http.Response(
            '{"items":[{"id":1,"title":"Film","genre":"Drama",'
            '"durationMin":120,"posterUrl":"","rating":8}]}',
            200,
          );
        }
        return http.Response('{"items":[]}', 200);
      });
      final model = CinemaModel(
        HttpCinemaRepository(
          'http://example.test',
          TokenStore(),
          client: client,
        ),
      );
      await model.loadMovies();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              width: 200,
              child: MovieCard(movie: model.movies.single),
            ),
          ),
        ),
      );
      expect(find.text('Drama · Год не указан'), findsOneWidget);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: model,
          child: const MaterialApp(home: MovieDetailScreen(id: '1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Год не указан · Режиссёр не указан'), findsOneWidget);
      expect(find.text('Описание не указано'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      model.dispose();
      client.close();
    },
  );
}
