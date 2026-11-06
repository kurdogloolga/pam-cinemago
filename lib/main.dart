import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/auth_api.dart';
import 'data/cinema_repository.dart';
import 'data/mock_cinema_repository.dart';
import 'data/token_store.dart';
import 'models/cinema_model.dart';
import 'models/seat_selection_model.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tokens = TokenStore();
  final loggedIn = await tokens.read() != null;
  const configuredApiBase = String.fromEnvironment('API_BASE_URL');
  final apiBase = configuredApiBase.isNotEmpty
      ? configuredApiBase
      : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8080'
      : 'http://localhost:8080';
  runApp(
    MyApp(
      auth: AuthApi(apiBase, tokens),
      router: createAppRouter(loggedIn: loggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.auth, required this.router});

  final AuthApi auth;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthApi>.value(value: auth),
        Provider<MockCinemaRepository>(create: (_) => MockCinemaRepository()),
        Provider<CinemaRepository>(
          create: (context) => context.read<MockCinemaRepository>(),
        ),
        ChangeNotifierProvider(
          create: (context) => CinemaModel(context.read<CinemaRepository>())
            ..loadMovies()
            ..loadReservations('u1'),
        ),
        ChangeNotifierProvider(create: (_) => SeatSelectionModel()),
      ],
      child: MaterialApp.router(
        title: 'CinemaGo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE53935)),
          textTheme: const TextTheme(
            titleLarge: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        routerConfig: router,
      ),
    );
  }
}
