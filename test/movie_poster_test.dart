import 'package:cinemago/models/movie.dart';
import 'package:cinemago/widgets/movie_poster.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  const movie = Movie(
    id: '1',
    title: 'Film',
    genre: 'Drama',
    year: null,
    director: null,
    durationMin: 120,
    posterUrl: '/files/7',
    rating: 8,
    description: null,
  );

  testWidgets('resolves a relative poster URL against the API base URL', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<String>.value(
        value: 'http://example.test:8080',
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(child: MoviePoster(movie: movie)),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as NetworkImage).url,
      'http://example.test:8080/files/7',
    );
  });
}
