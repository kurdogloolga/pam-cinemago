// widgets/movie_poster.dart — постер фильма или стилизованная заглушка.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';

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
    final Widget poster;
    if (movie.posterUrl.isEmpty) {
      poster = Icon(
        Icons.movie_creation_outlined,
        size: iconSize,
        color: scheme.onPrimary.withValues(alpha: 0.6),
      );
    } else {
      final baseUrl = context.read<String>();
      poster = Image.network(
        Uri.parse(baseUrl).resolve(movie.posterUrl).toString(),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.broken_image_outlined,
          size: iconSize,
          color: scheme.onPrimary.withValues(alpha: 0.6),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors(scheme),
        ),
      ),
      child: Center(child: poster),
    );
  }
}
