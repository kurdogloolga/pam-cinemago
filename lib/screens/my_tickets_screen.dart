import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/movie_poster.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reservations = mockReservations
        .where((reservation) => reservation.userId == 'u1')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои билеты'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'Помощь',
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Ваши бронирования',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Здесь собраны билеты и статусы бронирований.',
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          const _TicketFilters(),
          const SizedBox(height: 18),
          ...reservations.map(
            (reservation) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _TicketCard(
                key: ValueKey('reservation-${reservation.id}'),
                reservation: reservation,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketFilters extends StatelessWidget {
  const _TicketFilters();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      children: [
        _TicketFilter(label: 'Все', selected: true),
        _TicketFilter(label: 'Предстоящие'),
        _TicketFilter(label: 'Завершённые'),
      ],
    );
  }
}

class _TicketFilter extends StatelessWidget {
  final String label;
  final bool selected;

  const _TicketFilter({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: null,
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Reservation reservation;

  const _TicketCard({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screening = mockScreenings.firstWhere(
      (item) => item.id == reservation.screeningId,
    );
    final movie = mockMovies.firstWhere(
      (item) => item.id == screening.movieId,
    );
    final (statusColor, statusBackground) = _statusColors(
      reservation.status,
      scheme,
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 88,
                    child: MoviePoster(movie: movie, iconSize: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${screening.day} · ${screening.time}',
                              style: textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.meeting_room_outlined,
                            size: 15,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(screening.hall, style: textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Места ${reservation.seats.join(', ')}',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          reservation.status,
                          style: textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${reservation.totalPrice.toStringAsFixed(0)} MDL',
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _statusColors(String status, ColorScheme scheme) {
    return switch (status) {
      'Подтверждено' => (scheme.primary, scheme.primaryContainer),
      'Ожидает оплаты' => (
        scheme.tertiary,
        scheme.tertiaryContainer,
      ),
      'Отменено' => (scheme.error, scheme.errorContainer),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
    };
  }
}
