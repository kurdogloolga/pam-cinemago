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

const mockMovies = [
  Movie(
    id: 'm1',
    title: 'Интерстеллар',
    genre: 'фантастика',
    year: 2014,
    director: 'Кристофер Нолан',
    durationMin: 169,
    posterUrl: '',
    rating: 8.7,
    description:
        'Земля умирает: неурожаи и пыльные бури вынуждают человечество искать новый дом. '
        'Бывший пилот Купер, ставший фермером, получает шанс присоединиться к тайной '
        'экспедиции NASA через червоточину возле Сатурна.\n\n'
        'Чтобы спасти людей, ему придётся оставить детей и отправиться к далёким '
        'галактикам, где время течёт иначе. Масштабная космическая драма о любви, '
        'долге и цене надежды с потрясающей музыкой Ханса Циммера.',
  ),
  Movie(
    id: 'm2',
    title: 'Начало',
    genre: 'триллер',
    year: 2010,
    director: 'Кристофер Нолан',
    durationMin: 148,
    posterUrl: '',
    rating: 8.8,
    description:
        'Дом Кобб — вор, который проникает в сны людей и крадёт секреты прямо из '
        'подсознания. В обмен на возможность вернуться к детям ему предлагают '
        'невозможное: не украсть идею, а внедрить её.\n\n'
        'Команда спускается на несколько уровней сновидений, где законы физики '
        'искажаются, а время растягивается. Умный, головокружительный блокбастер, '
        'после которого хочется сразу обсудить финал.',
  ),
  Movie(
    id: 'm3',
    title: 'Тёмный рыцарь',
    genre: 'боевик',
    year: 2008,
    director: 'Кристофер Нолан',
    durationMin: 152,
    posterUrl: '',
    rating: 9.0,
    description:
        'Готэм погружается в хаос: мафия теряет контроль, а на улицах появляется '
        'Джокер — преступник без правил и без мотива. Бэтмен, прокурор Харви Дент '
        'и комиссар Гордон пытаются его остановить.\n\n'
        'Это не просто экранизация комикса, а мрачный криминальный триллер о границе '
        'между героизмом и местью. Роль Джокера в исполнении Хита Леджера стала '
        'одной из самых обсуждаемых в истории кино.',
  ),
  Movie(
    id: 'm4',
    title: '1+1',
    genre: 'комедия',
    year: 2011,
    director: 'Оливье Накаш, Эрик Толедано',
    durationMin: 112,
    posterUrl: '',
    rating: 8.5,
    description:
        'Парализованный аристократ Филипп ищет сиделку и неожиданно выбирает бывшего '
        'заключённого Дрисса — единственного, кто не смотрит на него с жалостью.\n\n'
        'Между людьми из разных миров рождается дружба, полная юмора, парижских улиц, '
        'оперы и быстрой езды. Светлая и тёплая история по мотивам реальных событий, '
        'после которой остаётся улыбка.',
  ),
  Movie(
    id: 'm5',
    title: 'Форрест Гамп',
    genre: 'мелодрама',
    year: 1994,
    director: 'Роберт Земекис',
    durationMin: 142,
    posterUrl: '',
    rating: 8.8,
    description:
        'Простодушный Форрест с детства слышит, что он не такой, как все, но жизнь '
        'снова и снова ставит его в центр великих событий — от университетского '
        'футбола до войны во Вьетнаме.\n\n'
        'Через всё это он несёт любовь к Дженни и простую веру: главное — оставаться '
        'добрым. Тёплая трагикомедия, в которой смех и слёзы идут рука об руку.',
  ),
  Movie(
    id: 'm6',
    title: 'Паразиты',
    genre: 'триллер',
    year: 2019,
    director: 'Пон Джун Хо',
    durationMin: 132,
    posterUrl: '',
    rating: 8.5,
    description:
        'Семья Ки живёт в тесном полуподвале и еле сводит концы с концами. Когда сын '
        'получает место репетитора в богатой семье Пак, в голове у всех зреет хитрый '
        'план.\n\n'
        'Чёрная комедия постепенно превращается в напряжённый триллер о социальном '
        'неравенстве. Первый неанглоязычный фильм, получивший «Оскар» как лучший '
        'фильм года.',
  ),
  Movie(
    id: 'm7',
    title: 'Король Лев',
    genre: 'мультфильм',
    year: 1994,
    director: 'Роджер Аллерс, Роб Минкофф',
    durationMin: 88,
    posterUrl: '',
    rating: 8.5,
    description:
        'Львёнок Симба — наследник престола саванны, но коварный дядя Шрам отнимает '
        'у него дом и заставляет поверить, что он виноват в гибели отца.\n\n'
        'Спустя годы, рядом с новыми друзьями Тимоном и Пумбой, Симбе предстоит '
        'вернуться и принять свою судьбу. Музыка Элтона Джона и Ханса Циммера '
        'сделала этот мультфильм вечной классикой.',
  ),
  Movie(
    id: 'm8',
    title: 'Побег из Шоушенка',
    genre: 'драма',
    year: 1994,
    director: 'Фрэнк Дарабонт',
    durationMin: 142,
    posterUrl: '',
    rating: 9.3,
    description:
        'Банкир Энди Дюфрейн несправедливо осуждён за убийство жены и попадает в '
        'тюрьму Шоушенк. Там он знакомится с Рэдом, который умеет достать что угодно.\n\n'
        'Годы за решёткой, жестокость надзирателей и маленькие победы — история о том, '
        'что надежда может быть сильнее стен. Многолетний лидер рейтингов IMDb.',
  ),
];

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

class Reservation {
  final String id;
  final String movieTitle;
  final String day;
  final String time;
  final String hall;
  final List<String> seats;
  final double totalPrice;
  final String status;

  const Reservation({
    required this.id,
    required this.movieTitle,
    required this.day,
    required this.time,
    required this.hall,
    required this.seats,
    required this.totalPrice,
    required this.status,
  });
}

const mockReservations = [
  Reservation(id: 'r1', movieTitle: 'Интерстеллар', day: '08 окт', time: '18:00', hall: 'Зал 1', seats: ['E4', 'E5'], totalPrice: 190, status: 'Подтверждено'),
  Reservation(id: 'r2', movieTitle: 'Начало', day: '08 окт', time: '20:15', hall: 'Зал 2', seats: ['D1'], totalPrice: 85, status: 'Ожидает оплаты'),
  Reservation(id: 'r3', movieTitle: 'Побег из Шоушенка', day: '09 окт', time: '19:15', hall: 'Зал 2', seats: ['B3', 'B4'], totalPrice: 200, status: 'Подтверждено'),
  Reservation(id: 'r4', movieTitle: 'Паразиты', day: '09 окт', time: '20:45', hall: 'Зал 1', seats: ['A6'], totalPrice: 95, status: 'Отменено'),
  Reservation(id: 'r5', movieTitle: 'Тёмный рыцарь', day: '10 окт', time: '20:00', hall: 'Зал 4', seats: ['C2', 'C3', 'C4'], totalPrice: 270, status: 'Подтверждено'),
  Reservation(id: 'r6', movieTitle: 'Король Лев', day: '08 окт', time: '12:00', hall: 'Зал 3', seats: ['F1', 'F2'], totalPrice: 150, status: 'Подтверждено'),
];