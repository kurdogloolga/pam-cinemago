// screens/screening_selection_screen.dart — выбор сеанса: группировка по дням и времени
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/movie_poster.dart';

class ScreeningSelectionScreen extends StatelessWidget {
  final Movie movie;

  const ScreeningSelectionScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final screenings =
        mockScreenings.where((s) => s.movieId == movie.id).toList();
    final days = screenings.map((s) => s.day).toSet().toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Выбор сеанса')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: days.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _MovieHeader(movie: movie);

          final day = days[index - 1];
          final dayScreenings =
              screenings.where((s) => s.day == day).toList();

          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      day,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: dayScreenings
                      .map((s) => _TimeCard(screening: s))
                      .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MovieHeader extends StatelessWidget {
  final Movie movie;

  const _MovieHeader({required this.movie});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 72,
            height: 104,
            child: MoviePoster(movie: movie, iconSize: 28),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${movie.genre} · ${movie.durationMin} мин',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(movie.rating.toStringAsFixed(1)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  final Screening screening;

  const _TimeCard({required this.screening});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 100,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Text(
                  screening.time,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  screening.hall,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${screening.price.toStringAsFixed(0)} MDL',
                  style: textTheme.labelLarge?.copyWith(color: scheme.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}