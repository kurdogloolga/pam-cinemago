// screens/movie_detail_screen.dart — карточка фильма: постер, описание, длительность, рейтинг, сеансы
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cinema_model.dart';
import '../widgets/movie_poster.dart';
import '../widgets/error_view.dart';

class MovieDetailScreen extends StatefulWidget {
  final String id;

  const MovieDetailScreen({super.key, required this.id});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadScreenings();
      }
    });
  }

  void _loadScreenings() {
    final model = context.read<CinemaModel>();
    if (!model.hasLoadedScreeningsFor(widget.id) &&
        !model.isScreeningsLoadingFor(widget.id)) {
      model.loadScreenings(widget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CinemaModel>();
    if (model.isMoviesLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (model.moviesError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Афиша')),
        body: ErrorView(
          message: model.moviesError!,
          onRetry: () => context.read<CinemaModel>().loadMovies(),
        ),
      );
    }

    final movie = model.movieById(widget.id);
    if (movie == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Фильм не найден')),
        body: Center(child: Text('Фильм не найден')),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenings = model.screeningsForMovie(movie.id).toList()
      ..sort((first, second) => first.dateTime.compareTo(second.dateTime));
    final screeningsError = model.screeningsErrorFor(movie.id);

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => context.push('/movies/${movie.id}/screenings'),
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
                        avatar: Icon(
                          Icons.star,
                          size: 18,
                          color: scheme.primary,
                        ),
                        label: Text(
                          '${movie.rating.toStringAsFixed(1)} рейтинг',
                        ),
                      ),
                      Chip(
                        avatar: Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: scheme.primary,
                        ),
                        label: Text('${movie.durationMin} мин'),
                      ),
                      Chip(
                        avatar: Icon(
                          Icons.local_movies_outlined,
                          size: 18,
                          color: scheme.primary,
                        ),
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
                  if (model.isScreeningsLoadingFor(movie.id))
                    const Center(child: CircularProgressIndicator())
                  else if (screeningsError != null)
                    ErrorView(
                      message: screeningsError,
                      onRetry: _loadScreenings,
                    )
                  else if (screenings.isEmpty)
                    const Text('Нет доступных сеансов')
                  else
                    Card(
                      child: Column(
                        children: screenings
                            .map(
                              (screening) => ListTile(
                                leading: Icon(
                                  Icons.schedule,
                                  color: scheme.primary,
                                ),
                                title: Text(
                                  '${screening.day} · ${screening.time}',
                                ),
                                subtitle: Text(screening.hall),
                                trailing: Text(
                                  '${screening.price.toStringAsFixed(0)} MDL',
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
