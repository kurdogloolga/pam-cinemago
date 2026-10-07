// data/mock_data.dart — модель Movie, зашитые в код данные о фильмах

class Movie {
  final String id;
  final String title;
  final String genre;
  final int durationMin;
  final String posterUrl;
  final double rating;

  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.durationMin,
    required this.posterUrl,
    required this.rating,
  });
}

const mockMovies = [
  Movie(
    id: 'm1',
    title: 'Дюна: Часть третья',
    genre: 'фантастика',
    durationMin: 165,
    posterUrl: '',
    rating: 8.3,
  ),
  Movie(
    id: 'm2',
    title: 'Тихий дом на окраине',
    genre: 'ужасы',
    durationMin: 102,
    posterUrl: '',
    rating: 7.1,
  ),
  Movie(
    id: 'm3',
    title: 'Последний рейс',
    genre: 'боевик',
    durationMin: 128,
    posterUrl: '',
    rating: 7.8,
  ),
  Movie(
    id: 'm4',
    title: 'Смешной случай в Кишинёве',
    genre: 'комедия',
    durationMin: 95,
    posterUrl: '',
    rating: 6.9,
  ),
  Movie(
    id: 'm5',
    title: 'Письма, которые не отправили',
    genre: 'мелодрама',
    durationMin: 118,
    posterUrl: '',
    rating: 7.5,
  ),
  Movie(
    id: 'm6',
    title: 'Город без имени',
    genre: 'триллер',
    durationMin: 134,
    posterUrl: '',
    rating: 8.0,
  ),
  Movie(
    id: 'm7',
    title: 'Приключения маленького дракона',
    genre: 'мультфильм',
    durationMin: 88,
    posterUrl: '',
    rating: 7.9,
  ),
  Movie(
    id: 'm8',
    title: 'Семь дней до рассвета',
    genre: 'драма',
    durationMin: 142,
    posterUrl: '',
    rating: 8.5,
  ),
];