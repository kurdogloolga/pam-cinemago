// screens/movies_screen.dart — Афиша: поиск + фильтр по жанру (визуально), сетка фильмов
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cinema_model.dart';
import '../widgets/movie_card.dart';
import '../widgets/error_view.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<CinemaModel>().movieSearch;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    context.read<CinemaModel>().loadMovies(search: query);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final model = context.watch<CinemaModel>();
    final movies = model.movies;
    final genres = ['Все', ...movies.map((movie) => movie.genre).toSet()];
    final Widget results;
    if (model.isMoviesLoading) {
      results = const Center(child: CircularProgressIndicator());
    } else if (model.moviesError != null) {
      results = ErrorView(
        message: model.moviesError!,
        onRetry: () => context.read<CinemaModel>().loadMovies(),
      );
    } else if (movies.isEmpty) {
      results = const Center(child: Text('Фильмы не найдены'));
    } else {
      results = GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.62,
        ),
        itemCount: movies.length + (model.hasMoreMovies ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == movies.length) {
            if (model.moviesMoreError != null) {
              return Center(
                child: TextButton(
                  onPressed: () => model.loadMoreMovies(),
                  child: const Text('Повторить загрузку'),
                ),
              );
            }
            if (!model.isLoadingMoreMovies) {
              unawaited(model.loadMoreMovies());
            }
            return const Center(child: CircularProgressIndicator());
          }
          final movie = movies[index];
          return MovieCard(
            movie: movie,
            onTap: () => context.push('/movies/${movie.id}'),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Афиша'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Поиск фильма...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: model.movieSearch.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Очистить поиск',
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
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
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final genre = genres[index];
                final query = index == 0 ? '' : genre;
                return ChoiceChip(
                  label: Text(genre),
                  selected: model.movieSearch == query,
                  onSelected: (selected) {
                    if (!selected) return;
                    _searchController.text = query;
                    _search(query);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: results),
        ],
      ),
    );
  }
}
