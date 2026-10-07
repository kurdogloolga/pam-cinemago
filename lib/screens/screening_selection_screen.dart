import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/movie_poster.dart';
import 'seat_selection_screen.dart';

class ScreeningSelectionScreen extends StatelessWidget {
  final Movie movie;

  const ScreeningSelectionScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenings = mockScreenings
        .where((screening) => screening.movieId == movie.id)
        .toList()
      ..sort(
        (first, second) => first.dateTime.compareTo(second.dateTime),
      );
    final days = screenings.map((screening) => screening.day).toSet().toList();
    final selectedDay = days.firstOrNull;
    final dayScreenings = screenings
        .where((screening) => screening.day == selectedDay)
        .toList();
    final selectedScreening = dayScreenings.firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Выбор сеанса'), centerTitle: true),
      body: screenings.isEmpty
          ? _EmptyScreenings(movieTitle: movie.title)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                _MovieHeader(movie: movie),
                const SizedBox(height: 28),
                Text(
                  'Выберите дату',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final isSelected = day == selectedDay;
                      final parts = day.split(' ');

                      return _DayChip(
                        date: parts.first,
                        month: parts.length > 1 ? parts[1] : '',
                        selected: isSelected,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Время сеанса',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${dayScreenings.length} ${_sessionCountLabel(dayScreenings.length)}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...dayScreenings.map(
                  (screening) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ScreeningCard(
                      screening: screening,
                      selected: screening.id == selectedScreening?.id,
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: screenings.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: FilledButton(
                  onPressed: selectedScreening == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => SeatSelectionScreen(
                                movie: movie,
                                screening: selectedScreening,
                              ),
                            ),
                          );
                        },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Продолжить'),
                      if (selectedScreening != null) ...[
                        const SizedBox(width: 8),
                        const Text('·'),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedScreening.price.toStringAsFixed(0)} MDL',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 76,
              height: 108,
              child: MoviePoster(movie: movie, iconSize: 32),
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
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${movie.genre}  ·  ${movie.durationMin} мин',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 19, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      movie.rating.toStringAsFixed(1),
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'рейтинг',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String date;
  final String month;
  final bool selected;

  const _DayChip({
    required this.date,
    required this.month,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 76,
      decoration: BoxDecoration(
        color: selected ? scheme.primary : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date,
            style: textTheme.titleMedium?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            month,
            style: textTheme.labelSmall?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreeningCard extends StatelessWidget {
  final Screening screening;
  final bool selected;

  const _ScreeningCard({
    required this.screening,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? scheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.12)
                  : scheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: scheme.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  screening.time,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  screening.hall,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${screening.price.toStringAsFixed(0)} MDL',
            style: textTheme.titleSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            selected ? Icons.check_circle : Icons.chevron_right,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            size: 21,
          ),
        ],
      ),
    );
  }
}

class _EmptyScreenings extends StatelessWidget {
  final String movieTitle;

  const _EmptyScreenings({required this.movieTitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Сеансов пока нет',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Для фильма «$movieTitle» пока не опубликовано расписание.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _sessionCountLabel(int count) {
  if (count % 10 == 1 && count % 100 != 11) return 'сеанс';
  if (count % 10 >= 2 &&
      count % 10 <= 4 &&
      (count % 100 < 12 || count % 100 > 14)) {
    return 'сеанса';
  }
  return 'сеансов';
}
