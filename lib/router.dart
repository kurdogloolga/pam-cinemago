import 'package:go_router/go_router.dart';

import 'screens/login_screen.dart';
import 'screens/movies_screen.dart';

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
  ],
);
