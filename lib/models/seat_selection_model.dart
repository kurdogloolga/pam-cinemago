import 'package:flutter/foundation.dart';

class SeatSelectionModel extends ChangeNotifier {
  final Map<String, Set<String>> _selectedSeatsByScreening = {};

  List<String> selectedSeatsFor(String screeningId) {
    return List.unmodifiable(
      _selectedSeatsByScreening[screeningId] ?? const <String>{},
    );
  }

  void toggleSeat(String screeningId, String seatId) {
    final selectedSeats = _selectedSeatsByScreening.putIfAbsent(
      screeningId,
      () => <String>{},
    );

    if (!selectedSeats.add(seatId)) {
      selectedSeats.remove(seatId);
      if (selectedSeats.isEmpty) {
        _selectedSeatsByScreening.remove(screeningId);
      }
    }

    notifyListeners();
  }

  void clearSelection(String screeningId) {
    final selectedSeats = _selectedSeatsByScreening.remove(screeningId);
    if (selectedSeats != null && selectedSeats.isNotEmpty) {
      notifyListeners();
    }
  }
}
