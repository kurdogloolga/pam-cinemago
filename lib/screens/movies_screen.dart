// screens/movies_screen.dart — Афиша фильмов: поиск + фильтр по жанру (визуально, без логики)
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/movie_card.dart';

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final genres = mockMovies.map((m) => m.genre).toSet().toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Афиша')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск фильма...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: genres.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ChoiceChip(
                label: Text(genres[index]),
                selected: false,
                onSelected: (_) {},
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: mockMovies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  MovieCard(movie: mockMovies[index]),
            ),
          ),
        ],
      ),
    );
  }
}