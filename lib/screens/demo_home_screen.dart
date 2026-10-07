import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import 'booking_confirmation_screen.dart';
import 'movie_detail_screen.dart';
import 'my_tickets_screen.dart';
import 'movies_screen.dart';
import 'profile_screen.dart';
import 'screening_selection_screen.dart';
import 'seat_selection_screen.dart';

class DemoHomeScreen extends StatelessWidget {
  const DemoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final movie = mockMovies.first;
    final screening = mockScreenings.first;

    return Scaffold(
      appBar: AppBar(title: const Text('CinemaGo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Экраны приложения',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите экран для демонстрации макета.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _DemoDestination(
            title: 'Афиша фильмов',
            icon: Icons.local_movies_outlined,
            onTap: () => _open(context, const MoviesScreen()),
          ),
          _DemoDestination(
            title: 'Карточка фильма',
            icon: Icons.movie_outlined,
            onTap: () => _open(context, MovieDetailScreen(movie: movie)),
          ),
          _DemoDestination(
            title: 'Выбор сеанса',
            icon: Icons.schedule_outlined,
            onTap: () => _open(context, ScreeningSelectionScreen(movie: movie)),
          ),
          _DemoDestination(
            title: 'Выбор мест',
            icon: Icons.event_seat_outlined,
            onTap: () => _open(
              context,
              SeatSelectionScreen(movie: movie, screening: screening),
            ),
          ),
          _DemoDestination(
            title: 'Подтверждение бронирования',
            icon: Icons.confirmation_number_outlined,
            onTap: () => _open(
              context,
              BookingConfirmationScreen(
                movie: movie,
                screening: screening,
                seats: const ['C4', 'C5'],
              ),
            ),
          ),
          _DemoDestination(
            title: 'Мои билеты',
            icon: Icons.confirmation_number_outlined,
            onTap: () => _open(context, const MyTicketsScreen()),
          ),
          _DemoDestination(
            title: 'Профиль',
            icon: Icons.person_outline,
            onTap: () => _open(context, const ProfileScreen()),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => screen));
  }
}

class _DemoDestination extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DemoDestination({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: scheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
