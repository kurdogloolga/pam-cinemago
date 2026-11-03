import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/cinema_repository.dart';
import 'data/mock_cinema_repository.dart';
import 'models/cinema_model.dart';
import 'models/seat_selection_model.dart';
import 'router.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CinemaRepository>(create: (_) => MockCinemaRepository()),
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
        routerConfig: appRouter,
      ),
    );
  }
}
