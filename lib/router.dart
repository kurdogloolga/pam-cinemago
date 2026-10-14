import 'package:go_router/go_router.dart';

import 'screens/login_screen.dart';
import 'screens/movies_screen.dart';
import 'screens/my_tickets_screen.dart';
import 'screens/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/movies',
      builder: (context, state) => const MoviesScreen(),
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
