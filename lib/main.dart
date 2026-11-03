import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/seat_selection_model.dart';
import 'router.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SeatSelectionModel(),
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
