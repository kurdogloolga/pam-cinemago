// screens/movie_detail_screen.dart — детали фильма: описание, длительность, рейтинг, сеансы
import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class MovieDetailScreen extends StatelessWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenings =
        mockScreenings.where((s) => s.movieId == movie.id).toList();

    return Scaffold(
      appBar: AppBar(title: Text(movie.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.movie,
              size: 64,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(movie.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 4),
              Text('${movie.durationMin} мин'),
              const SizedBox(width: 16),
              Icon(Icons.local_movies_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 4),
              Text(movie.genre),
              const SizedBox(width: 16),
              Icon(Icons.star, size: 18, color: scheme.primary),
              const SizedBox(width: 4),
              Text(movie.rating.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            movie.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('Доступные сеансы', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: screenings
                  .map(
                    (s) => ListTile(
                      leading: Icon(Icons.schedule, color: scheme.primary),
                      title: Text('${s.day} · ${s.time}'),
                      subtitle: Text(s.hall),
                      trailing: Text(
                        '${s.price.toStringAsFixed(0)} MDL',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}