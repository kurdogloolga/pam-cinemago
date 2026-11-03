import 'package:cinemago/models/seat_selection_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selected seats are isolated by screening', () {
    final model = SeatSelectionModel();

    model.toggleSeat('screening-1', 'A1');
    model.toggleSeat('screening-2', 'B2');

    expect(model.selectedSeatsFor('screening-1'), ['A1']);
    expect(model.selectedSeatsFor('screening-2'), ['B2']);
  });

  test('toggling and clearing seats notify listeners', () {
    final model = SeatSelectionModel();
    var notifications = 0;
    model.addListener(() => notifications++);

    model.toggleSeat('screening-1', 'A1');
    expect(notifications, 1);
    expect(model.selectedSeatsFor('screening-1'), ['A1']);

    model.toggleSeat('screening-1', 'A1');
    expect(notifications, 2);
    expect(model.selectedSeatsFor('screening-1'), isEmpty);

    model.toggleSeat('screening-1', 'A1');
    model.clearSelection('screening-1');
    expect(notifications, 4);
    expect(model.selectedSeatsFor('screening-1'), isEmpty);
  });

  test('selected seats cannot be modified by consumers', () {
    final model = SeatSelectionModel()..toggleSeat('screening-1', 'A1');
    final selectedSeats = model.selectedSeatsFor('screening-1');

    expect(() => selectedSeats.add('B2'), throwsUnsupportedError);
    expect(model.selectedSeatsFor('screening-1'), ['A1']);
  });
}
