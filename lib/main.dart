import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/auth_api.dart';
import 'data/http_cinema_repository.dart';
import 'data/token_store.dart';
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
  late final GoRouter router;
  final repository = HttpCinemaRepository(
    apiBase,
    tokens,
    onUnauthorized: () => router.go('/login'),
  );
  router = createAppRouter(loggedIn: loggedIn, repository: repository);
  runApp(
    MyApp(auth: AuthApi(apiBase, tokens), router: router, apiBaseUrl: apiBase),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.auth,
    required this.router,
    this.apiBaseUrl = 'http://localhost:8080',
  });

  final AuthApi auth;
  final GoRouter router;
  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    return Provider<AuthApi>.value(
      value: auth,
      child: Provider<String>.value(
        value: apiBaseUrl,
        child: MaterialApp.router(
          title: 'CinemaGo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE53935),
            ),
            textTheme: const TextTheme(
              titleLarge: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          routerConfig: router,
        ),
      ),
    );
  }
}
