import 'package:cinemago/data/mock_data.dart';
import 'package:cinemago/screens/booking_confirmation_screen.dart';
import 'package:cinemago/screens/my_tickets_screen.dart';
import 'package:cinemago/screens/profile_screen.dart';
import 'package:cinemago/screens/seat_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('seat map shows 8 rows, 10 seats and all seat states', (
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
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('seat-A1')))
          .properties
          .label,
      'Ряд A, место 1, занято',
    );
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('seat-C4')))
          .properties
          .label,
      'Ряд C, место 4, выбрано',
    );
    await tester.scrollUntilVisible(
      find.text('Выбрано мест: 2'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Выбрано мест: 2'), findsOneWidget);
    expect(find.text('190 MDL'), findsOneWidget);
  });

  testWidgets('booking confirmation shows screening, seats and total', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BookingConfirmationScreen(
          movie: mockMovies.first,
          screening: mockScreenings.first,
          seats: const ['C4', 'C5'],
        ),
      ),
    );

    expect(find.text('Подтверждение брони'), findsOneWidget);
    expect(find.text('Интерстеллар'), findsOneWidget);
    expect(find.text('8 окт · 18:00'), findsOneWidget);
    expect(find.text('Зал 1'), findsOneWidget);
    expect(find.text('Подтвердить бронирование'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Итого'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('190 MDL'), findsNWidgets(2));
  });

  testWidgets('my tickets shows reservation details and statuses', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MyTicketsScreen()));

    expect(find.text('Ваши бронирования'), findsOneWidget);
    expect(mockReservations, hasLength(6));
    expect(find.text('Интерстеллар'), findsOneWidget);
    expect(find.text('Подтверждено'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Места E4, E5'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Места E4, E5'), findsOneWidget);
  });

  testWidgets('profile shows account details and static settings', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    expect(find.text('Профиль'), findsOneWidget);
    expect(find.text('Анастасия Иванова'), findsOneWidget);
    expect(find.text('anastasia.ivanova@example.com'), findsOneWidget);
    expect(find.text('+373 69 123 456'), findsOneWidget);
    expect(find.text('Язык приложения'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Помощь и поддержка'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Помощь и поддержка'), findsOneWidget);
    expect(find.text('Выйти из аккаунта'), findsOneWidget);
  });
}
