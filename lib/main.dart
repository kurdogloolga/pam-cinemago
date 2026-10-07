import 'package:flutter/material.dart';
import 'data/mock_data.dart';
import 'screens/seat_selection_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinemaGo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      home: SeatSelectionScreen(
        movie: mockMovies.first,
        screening: mockScreenings.first,
      ),
    );
  }
}