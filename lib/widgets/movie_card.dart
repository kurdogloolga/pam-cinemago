// widgets/movie_card.dart — переиспользуемая карточка фильма (афиша + возможно избранное)
import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;

  const MovieCard({super.key, required this.movie, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(Icons.movie, color: scheme.onPrimaryContainer),
        ),
        title: Text(movie.title),
        subtitle: Text('${movie.genre} · ${movie.durationMin} мин'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 16, color: scheme.primary),
            const SizedBox(width: 4),
            Text(
              movie.rating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}