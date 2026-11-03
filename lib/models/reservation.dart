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
