class Movie {
  final String id;
  final String title;
  final String genre;
  final int year;
  final String director;
  final int durationMin;
  final String posterUrl;
  final double rating;
  final String description;

  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.director,
    required this.durationMin,
    required this.posterUrl,
    required this.rating,
    required this.description,
  });
}
