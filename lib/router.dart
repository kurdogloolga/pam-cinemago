import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/mock_data.dart';
import 'screens/login_screen.dart';
import 'screens/booking_confirmation_screen.dart';
import 'screens/movie_detail_screen.dart';
import 'screens/movies_screen.dart';
import 'screens/my_tickets_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/screening_selection_screen.dart';
import 'screens/seat_selection_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/movies',
      builder: (context, state) => const MoviesScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) =>
              MovieDetailScreen(id: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'screenings',
              builder: (context, state) {
                final movie = mockMovies
                    .where((movie) => movie.id == state.pathParameters['id'])
                    .firstOrNull;
                if (movie == null) {
                  return _notFoundScreen('Фильм не найден');
                }
                return ScreeningSelectionScreen(movie: movie);
              },
              routes: [
                GoRoute(
                  path: ':screeningId/seats',
                  builder: (context, state) {
                    final movie = mockMovies
                        .where(
                          (movie) => movie.id == state.pathParameters['id'],
                        )
                        .firstOrNull;
                    final screening = mockScreenings
                        .where(
                          (screening) =>
                              screening.id ==
                              state.pathParameters['screeningId'],
                        )
                        .firstOrNull;
                    if (movie == null || screening == null) {
                      return _notFoundScreen('Сеанс не найден');
                    }
                    return SeatSelectionScreen(
                      movie: movie,
                      screening: screening,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'confirmation',
                      builder: (context, state) {
                        final movie = mockMovies
                            .where(
                              (movie) => movie.id == state.pathParameters['id'],
                            )
                            .firstOrNull;
                        final screening = mockScreenings
                            .where(
                              (screening) =>
                                  screening.id ==
                                  state.pathParameters['screeningId'],
                            )
                            .firstOrNull;
                        if (movie == null || screening == null) {
                          return _notFoundScreen('Бронирование не найдено');
                        }
                        return BookingConfirmationScreen(
                          movie: movie,
                          screening: screening,
                          seats:
                              state.uri.queryParametersAll['seats'] ?? const [],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/tickets',
      builder: (context, state) => const MyTicketsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);

Scaffold _notFoundScreen(String message) {
  return Scaffold(
    appBar: AppBar(title: const Text('Не найдено')),
    body: Center(child: Text(message)),
  );
}
