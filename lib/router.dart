import 'package:go_router/go_router.dart';

import 'screens/booking_confirmation_screen.dart';
import 'screens/login_screen.dart';
import 'screens/movie_detail_screen.dart';
import 'screens/movies_screen.dart';
import 'screens/my_tickets_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/screening_selection_screen.dart';
import 'screens/seat_selection_screen.dart';
import 'widgets/app_shell.dart';

final appRouter = createAppRouter();

GoRouter createAppRouter({bool loggedIn = false}) => GoRouter(
  initialLocation: loggedIn ? '/movies' : '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
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
                      builder: (context, state) => ScreeningSelectionScreen(
                        movieId: state.pathParameters['id']!,
                      ),
                      routes: [
                        GoRoute(
                          path: ':screeningId/seats',
                          builder: (context, state) {
                            return SeatSelectionScreen(
                              movieId: state.pathParameters['id']!,
                              screeningId: state.pathParameters['screeningId']!,
                            );
                          },
                          routes: [
                            GoRoute(
                              path: 'confirmation',
                              builder: (context, state) {
                                return BookingConfirmationScreen(
                                  movieId: state.pathParameters['id']!,
                                  screeningId:
                                      state.pathParameters['screeningId']!,
                                  seats:
                                      state.uri.queryParametersAll['seats'] ??
                                      const [],
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
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tickets',
              builder: (context, state) => const MyTicketsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
