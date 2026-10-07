// widgets/movie_card.dart — вертикальная карточка фильма для сетки афиши
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import 'movie_poster.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;

  const MovieCard({super.key, required this.movie, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MoviePoster(movie: movie),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.scrim.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 14, color: scheme.inversePrimary),
                        const SizedBox(width: 4),
                        Text(
                          movie.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: scheme.surface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            '${movie.genre} · ${movie.year}',
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}