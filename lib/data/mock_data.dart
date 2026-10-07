// data/mock_data.dart — модели Movie и Screening, зашитые в код данные

class Movie {
  final String id;
  final String title;
  final String genre;
  final int durationMin;
  final String posterUrl;
  final double rating;
  final String description;

  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.durationMin,
    required this.posterUrl,
    required this.rating,
    required this.description,
  });
}

class Screening {
  final String id;
  final String movieId;
  final String hall;
  final String day;
  final String time;
  final double price;
  final List<String> seatsTaken;

  const Screening({
    required this.id,
    required this.movieId,
    required this.hall,
    required this.day,
    required this.time,
    required this.price,
    required this.seatsTaken,
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
    description:
        'Пол Атрейдес объединяет силы фрименов, чтобы отомстить заговорщикам, '
        'уничтожившим его семью. Эпическое завершение трилогии о пустынной планете Арракис.',
  ),
  Movie(
    id: 'm2',
    title: 'Тихий дом на окраине',
    genre: 'ужасы',
    durationMin: 102,
    posterUrl: '',
    rating: 7.1,
    description:
        'Семья переезжает в старый дом на окраине города и обнаруживает, что '
        'у прежних хозяев были веские причины его покинуть.',
  ),
  Movie(
    id: 'm3',
    title: 'Последний рейс',
    genre: 'боевик',
    durationMin: 128,
    posterUrl: '',
    rating: 7.8,
    description:
        'Экипаж грузового судна оказывается в центре международного заговора '
        'после того, как на борту обнаруживается секретный груз.',
  ),
  Movie(
    id: 'm4',
    title: 'Смешной случай в Кишинёве',
    genre: 'комедия',
    durationMin: 95,
    posterUrl: '',
    rating: 6.9,
    description:
        'Два друга детства случайно становятся виновниками городского переполоха '
        'за сутки до большой свадьбы.',
  ),
  Movie(
    id: 'm5',
    title: 'Письма, которые не отправили',
    genre: 'мелодрама',
    durationMin: 118,
    posterUrl: '',
    rating: 7.5,
    description:
        'История двух людей, чья переписка длиной в десять лет меняет '
        'представление о времени, расстоянии и настоящей близости.',
  ),
  Movie(
    id: 'm6',
    title: 'Город без имени',
    genre: 'триллер',
    durationMin: 134,
    posterUrl: '',
    rating: 8.0,
    description:
        'Детектив расследует серию исчезновений в городе, которого официально '
        'не существует ни на одной карте.',
  ),
  Movie(
    id: 'm7',
    title: 'Приключения маленького дракона',
    genre: 'мультфильм',
    durationMin: 88,
    posterUrl: '',
    rating: 7.9,
    description:
        'Маленький дракон, который боится высоты, отправляется в путешествие, '
        'чтобы спасти свою деревню от вечной зимы.',
  ),
  Movie(
    id: 'm8',
    title: 'Семь дней до рассвета',
    genre: 'драма',
    durationMin: 142,
    posterUrl: '',
    rating: 8.5,
    description:
        'Врач провинциальной больницы принимает решение, которое навсегда '
        'изменит жизнь целого посёлка — у него есть всего семь дней.',
  ),
];

const mockScreenings = [
  Screening(id: 's1', movieId: 'm1', hall: 'Зал 1', day: '08 окт', time: '18:00', price: 95, seatsTaken: ['A1', 'A2', 'B5']),
  Screening(id: 's2', movieId: 'm1', hall: 'Зал 1', day: '08 окт', time: '21:00', price: 110, seatsTaken: ['C3']),
  Screening(id: 's3', movieId: 'm1', hall: 'Зал 3', day: '09 окт', time: '19:30', price: 95, seatsTaken: []),
  Screening(id: 's4', movieId: 'm2', hall: 'Зал 2', day: '08 окт', time: '20:15', price: 85, seatsTaken: ['D4', 'D5']),
  Screening(id: 's5', movieId: 'm2', hall: 'Зал 2', day: '09 окт', time: '22:00', price: 85, seatsTaken: []),
  Screening(id: 's6', movieId: 'm3', hall: 'Зал 1', day: '08 окт', time: '17:30', price: 90, seatsTaken: ['A1']),
  Screening(id: 's7', movieId: 'm3', hall: 'Зал 4', day: '10 окт', time: '20:00', price: 90, seatsTaken: []),
  Screening(id: 's8', movieId: 'm4', hall: 'Зал 3', day: '08 окт', time: '16:00', price: 80, seatsTaken: []),
  Screening(id: 's9', movieId: 'm4', hall: 'Зал 3', day: '09 окт', time: '18:30', price: 80, seatsTaken: ['B2', 'B3']),
  Screening(id: 's10', movieId: 'm5', hall: 'Зал 2', day: '08 окт', time: '19:00', price: 85, seatsTaken: []),
  Screening(id: 's11', movieId: 'm5', hall: 'Зал 2', day: '10 окт', time: '21:30', price: 85, seatsTaken: ['A5']),
  Screening(id: 's12', movieId: 'm6', hall: 'Зал 1', day: '09 окт', time: '20:45', price: 95, seatsTaken: []),
  Screening(id: 's13', movieId: 'm6', hall: 'Зал 4', day: '10 окт', time: '18:00', price: 95, seatsTaken: ['C1', 'C2']),
  Screening(id: 's14', movieId: 'm7', hall: 'Зал 3', day: '08 окт', time: '12:00', price: 75, seatsTaken: []),
  Screening(id: 's15', movieId: 'm7', hall: 'Зал 3', day: '09 окт', time: '14:30', price: 75, seatsTaken: []),
  Screening(id: 's16', movieId: 'm8', hall: 'Зал 2', day: '09 окт', time: '19:15', price: 100, seatsTaken: ['A1', 'A2', 'A3']),
  Screening(id: 's17', movieId: 'm8', hall: 'Зал 1', day: '10 окт', time: '21:00', price: 100, seatsTaken: []),
];