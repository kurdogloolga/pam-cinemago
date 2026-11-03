import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cinema_model.dart';
import '../models/movie.dart';
import '../models/reservation.dart';
import '../models/screening.dart';
import '../widgets/error_view.dart';
import '../widgets/movie_poster.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTickets();
      }
    });
  }

  Future<void> _loadTickets() async {
    final model = context.read<CinemaModel>();
    if (model.movies.isEmpty) {
      await model.loadMovies();
    }
    await model.loadReservations('u1');
    await model.loadAllScreenings();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CinemaModel>();
    final isLoading =
        model.isMoviesLoading ||
        model.isReservationsLoading ||
        model.isAnyScreeningsLoading;
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мои билеты'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final error =
        model.moviesError ??
        model.reservationsError ??
        model.firstScreeningsError;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мои билеты'), centerTitle: true),
        body: ErrorView(message: error, onRetry: _loadTickets),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final reservations = model.reservations;

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
          if (reservations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Бронирований пока нет')),
            )
          else
            ...reservations.map((reservation) {
              final screening = model.screeningById(reservation.screeningId);
              final movie = screening == null
                  ? null
                  : model.movieById(screening.movieId);
              if (screening == null || movie == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _TicketCard(
                  key: ValueKey('reservation-${reservation.id}'),
                  reservation: reservation,
                  screening: screening,
                  movie: movie,
                ),
              );
            }),
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
    return ChoiceChip(label: Text(label), selected: selected, onSelected: null);
  }
}

class _TicketCard extends StatelessWidget {
  final Reservation reservation;
  final Screening screening;
  final Movie movie;

  const _TicketCard({
    super.key,
    required this.reservation,
    required this.screening,
    required this.movie,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
      'Ожидает оплаты' => (scheme.tertiary, scheme.tertiaryContainer),
      'Отменено' => (scheme.error, scheme.errorContainer),
      _ => (scheme.onSurfaceVariant, scheme.surfaceContainerHighest),
    };
  }
}
