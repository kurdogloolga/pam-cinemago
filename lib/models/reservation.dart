class Reservation {
  final String id;
  final String screeningId;
  final String userId;
  final List<String> seats;
  final double totalPrice;
  final String status;

  const Reservation({
    required this.id,
    required this.screeningId,
    required this.userId,
    required this.seats,
    required this.totalPrice,
    required this.status,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
    id: (json['id'] as int).toString(),
    screeningId: (json['screeningId'] as int).toString(),
    userId: (json['userId'] as int).toString(),
    seats: List<String>.unmodifiable(
      (json['seats'] as List).map((seat) => seat as String),
    ),
    totalPrice: (json['totalPrice'] as num).toDouble(),
    status: json['status'] as String,
  );

  Map<String, Object> toJson() => {
    'screeningId': int.parse(screeningId),
    'seats': seats,
    'status': status,
  };

  Reservation copyWith({
    String? id,
    String? screeningId,
    String? userId,
    List<String>? seats,
    double? totalPrice,
    String? status,
  }) {
    return Reservation(
      id: id ?? this.id,
      screeningId: screeningId ?? this.screeningId,
      userId: userId ?? this.userId,
      seats: seats ?? this.seats,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
    );
  }
}
