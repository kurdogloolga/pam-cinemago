import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import 'booking_confirmation_screen.dart';

class SeatSelectionScreen extends StatelessWidget {
  final Movie movie;
  final Screening screening;

  static const _previewSelectedSeats = {'C4', 'C5'};

  const SeatSelectionScreen({
    super.key,
    required this.movie,
    required this.screening,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selectedSeats = _previewSelectedSeats
        .where((seat) => !screening.seatsTaken.contains(seat))
        .toSet();
    final total = screening.price * selectedSeats.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Выбор мест'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _ScreeningSummary(movie: movie, screening: screening),
          const SizedBox(height: 28),
          Text(
            'Выберите места',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Схема показывает свободные, занятые и выбранные места',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 26),
          _CinemaScreen(),
          const SizedBox(height: 8),
          Text(
            'ЭКРАН',
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),
          _SeatGrid(
            takenSeats: screening.seatsTaken.toSet(),
            selectedSeats: selectedSeats,
          ),
          const SizedBox(height: 28),
          const _SeatLegend(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.event_seat_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedSeats.isEmpty
                        ? 'Места не выбраны'
                        : 'Выбрано мест: ${selectedSeats.length}',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(0)} MDL',
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: FilledButton(
            onPressed: selectedSeats.isEmpty
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => BookingConfirmationScreen(
                          movie: movie,
                          screening: screening,
                          seats: selectedSeats.toList(),
                        ),
                      ),
                    );
                  },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              selectedSeats.isEmpty
                  ? 'Выберите места'
                  : 'Продолжить · ${total.toStringAsFixed(0)} MDL',
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreeningSummary extends StatelessWidget {
  final Movie movie;
  final Screening screening;

  const _ScreeningSummary({required this.movie, required this.screening});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _SummaryItem(
                icon: Icons.calendar_today_outlined,
                label: screening.day,
              ),
              _SummaryItem(icon: Icons.schedule_rounded, label: screening.time),
              _SummaryItem(
                icon: Icons.meeting_room_outlined,
                label: screening.hall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${screening.price.toStringAsFixed(0)} MDL за место',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _CinemaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 7,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.2),
            scheme.primary,
            scheme.primary.withValues(alpha: 0.2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.2),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _SeatGrid extends StatelessWidget {
  final Set<String> takenSeats;
  final Set<String> selectedSeats;

  const _SeatGrid({
    required this.takenSeats,
    required this.selectedSeats,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const rowLabels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    const seatCount = 10;

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 22),
            for (var seat = 0; seat < seatCount; seat++)
              Expanded(
                child: Center(
                  child: Text(
                    '${seat + 1}',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (var row = 0; row < rowLabels.length; row++) ...[
          Row(
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  rowLabels[row],
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (var seat = 0; seat < seatCount; seat++) ...[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _Seat(
                        id: '${rowLabels[row]}${seat + 1}',
                        taken: takenSeats.contains('${rowLabels[row]}${seat + 1}'),
                        selected:
                            selectedSeats.contains('${rowLabels[row]}${seat + 1}'),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (row < rowLabels.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _Seat extends StatelessWidget {
  final String id;
  final bool taken;
  final bool selected;

  const _Seat({
    required this.id,
    required this.taken,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = taken
        ? scheme.surfaceContainerHighest
        : selected
        ? scheme.primary
        : scheme.surface;
    final foreground = selected ? scheme.onPrimary : scheme.primary;

    return Semantics(
      key: ValueKey('seat-$id'),
      label:
          'Ряд ${id[0]}, место ${id.substring(1)}'
          '${taken
              ? ', занято'
              : selected
              ? ', выбрано'
              : ', свободно'}',
      child: AspectRatio(
        aspectRatio: 1,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: taken
                    ? Colors.transparent
                    : selected
                    ? scheme.primary
                    : scheme.outlineVariant,
              ),
            ),
            child: selected
                ? Icon(Icons.check, size: 15, color: foreground)
                : null,
          ),
        ),
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 12,
      children: [
        _LegendItem(
          color: scheme.surface,
          borderColor: scheme.outlineVariant,
          label: 'Свободно',
        ),
        _LegendItem(color: scheme.surfaceContainerHighest, label: 'Занято'),
        _LegendItem(color: scheme.primary, label: 'Выбрано'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color? borderColor;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 17,
          height: 17,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: borderColor ?? Colors.transparent),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
