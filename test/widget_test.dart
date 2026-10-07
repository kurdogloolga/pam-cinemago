import 'package:cinemago/data/mock_data.dart';
import 'package:cinemago/screens/seat_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('seat map has 8 rows of 10 seats and supports selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SeatSelectionScreen(
          movie: mockMovies.first,
          screening: mockScreenings.first,
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.key is ValueKey<String>,
      ),
      findsNWidgets(80),
    );
    expect(find.text('Выберите места'), findsNWidgets(2));

    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('seat-C1')));
    await tester.pump();

    expect(find.text('Продолжить · 95 MDL'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('seat-A1')));
    await tester.pump();

    expect(find.text('Продолжить · 95 MDL'), findsOneWidget);
  });
}
