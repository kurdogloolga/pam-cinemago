class Screening {
  final String id;
  final String movieId;
  final String hall;
  final DateTime dateTime;
  final double price;
  final List<String> seatsTaken;

  const Screening({
    required this.id,
    required this.movieId,
    required this.hall,
    required this.dateTime,
    required this.price,
    required this.seatsTaken,
  });

  factory Screening.fromJson(Map<String, dynamic> json) => Screening(
    id: (json['id'] as int).toString(),
    movieId: (json['movieId'] as int).toString(),
    hall: json['hall'] as String,
    dateTime: DateTime.parse(json['dateTime'] as String).toLocal(),
    price: (json['price'] as num).toDouble(),
    seatsTaken: List<String>.unmodifiable(
      (json['seatsTaken'] as List).map((seat) => seat as String),
    ),
  );

  String get day => '${dateTime.day} ${_russianMonths[dateTime.month - 1]}';

  String get time =>
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}';
}

const _russianMonths = [
  'янв',
  'фев',
  'мар',
  'апр',
  'май',
  'июн',
  'июл',
  'авг',
  'сен',
  'окт',
  'ноя',
  'дек',
];
