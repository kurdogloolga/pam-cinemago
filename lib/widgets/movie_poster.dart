// widgets/movie_poster.dart — стилизованный постер-заглушка (градиент из цветов темы)
import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class MoviePoster extends StatelessWidget {
  final Movie movie;
  final double iconSize;

  const MoviePoster({super.key, required this.movie, this.iconSize = 48});

  List<Color> _gradientColors(ColorScheme s) {
    final palettes = [
      [s.primary, s.tertiary],
      [s.secondary, s.primary],
      [s.tertiary, s.secondary],
      [s.primary, s.secondary],
    ];
    final seed = movie.id.codeUnits.fold<int>(0, (a, b) => a + b);
    return palettes[seed % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors(scheme),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.movie_creation_outlined,
          size: iconSize,
          color: scheme.onPrimary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}