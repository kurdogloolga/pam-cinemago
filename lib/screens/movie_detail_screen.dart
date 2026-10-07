// screens/movie_detail_screen.dart — карточка фильма: постер, описание, длительность, рейтинг, сеансы
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/movie_poster.dart';

class MovieDetailScreen extends StatelessWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenings =
        mockScreenings.where((s) => s.movieId == movie.id).toList()
          ..sort((first, second) => first.dateTime.compareTo(second.dateTime));

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.confirmation_number_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Выбрать сеанс'),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 320,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  MoviePoster(movie: movie, iconSize: 96),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          scheme.surface.withValues(alpha: 0),
                          scheme.surface,
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movie.year} · ${movie.director}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: Icon(Icons.star, size: 18, color: scheme.primary),
                        label: Text('${movie.rating.toStringAsFixed(1)} рейтинг'),
                      ),
                      Chip(
                        avatar: Icon(Icons.timer_outlined, size: 18, color: scheme.primary),
                        label: Text('${movie.durationMin} мин'),
                      ),
                      Chip(
                        avatar: Icon(Icons.local_movies_outlined, size: 18, color: scheme.primary),
                        label: Text(movie.genre),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('О фильме', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    movie.description,
                    style: textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Text('Доступные сеансы', style: textTheme.titleMedium),
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
                                style: textTheme.titleSmall,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}