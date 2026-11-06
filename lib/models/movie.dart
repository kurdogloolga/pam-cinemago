class Movie {
  final String id;
  final String title;
  final String genre;
  final int? year;
  final String? director;
  final int durationMin;
  final String posterUrl;
  final double rating;
  final String? description;

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

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
    id: (json['id'] as int).toString(),
    title: json['title'] as String,
    genre: json['genre'] as String,
    year: null,
    director: null,
    durationMin: json['durationMin'] as int,
    posterUrl: json['posterUrl'] as String,
    rating: (json['rating'] as num).toDouble(),
    description: null,
  );
}
