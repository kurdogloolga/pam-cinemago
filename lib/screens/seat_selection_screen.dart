import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Movie movie;
  final Screening screening;

  const SeatSelectionScreen({
    super.key,
    required this.movie,
    required this.screening,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _selectionErrorKey = GlobalKey();
  Set<String> _selectedSeats = {};
  String? _selectionError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: FormField<Set<String>>(
        initialValue: _selectedSeats,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (seats) => seats == null || seats.isEmpty
            ? 'Выберите минимум одно место'
            : null,
        builder: (field) {
          final total = widget.screening.price * _selectedSeats.length;

          return Scaffold(
            appBar: AppBar(title: const Text('Выбор мест'), centerTitle: true),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                _ScreeningSummary(
                  movie: widget.movie,
                  screening: widget.screening,
                ),
                const SizedBox(height: 28),
                Text(
                  'Выберите места',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SeatGrid(
                      takenSeats: widget.screening.seatsTaken.toSet(),
                      selectedSeats: _selectedSeats,
                      onSeatTap: (seat) {
                        final updatedSeats = Set<String>.of(_selectedSeats);
                        if (!updatedSeats.add(seat)) {
                          updatedSeats.remove(seat);
                        }
                        setState(() {
                          _selectedSeats = updatedSeats;
                          _selectionError = null;
                        });
                        field.didChange(updatedSeats);
                      },
                    ),
                    if (_selectionError != null || field.errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        key: _selectionErrorKey,
                        _selectionError ?? field.errorText!,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ],
                  ],
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
                          _selectedSeats.isEmpty
                              ? 'Места не выбраны'
                              : 'Выбрано мест: ${_selectedSeats.length}',
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
                  onPressed: () {
                    final valid = _formKey.currentState!.validate();
                    setState(() {
                      _selectionError = valid
                          ? null
                          : 'Выберите минимум одно место';
                    });
                    if (!valid) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        final errorContext = _selectionErrorKey.currentContext;
                        if (errorContext != null) {
                          Scrollable.ensureVisible(
                            errorContext,
                            alignment: 0.8,
                            duration: const Duration(milliseconds: 250),
                          );
                        }
                      });
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Места выбраны: ${_selectedSeats.join(', ')}',
                        ),
                      ),
                    );
                    final query = _selectedSeats
                        .map(
                          (seat) => 'seats=${Uri.encodeQueryComponent(seat)}',
                        )
                        .join('&');
                    context.push(
                      '/movies/${widget.movie.id}/screenings/'
                      '${widget.screening.id}/seats/confirmation?$query',
                    );
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _selectedSeats.isEmpty
                        ? 'Выберите места'
                        : 'Продолжить · ${total.toStringAsFixed(0)} MDL',
                  ),
                ),
              ),
            ),
          );
        },
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
  final ValueChanged<String> onSeatTap;

  const _SeatGrid({
    required this.takenSeats,
    required this.selectedSeats,
    required this.onSeatTap,
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
                      taken: takenSeats.contains(
                        '${rowLabels[row]}${seat + 1}',
                      ),
                      selected: selectedSeats.contains(
                        '${rowLabels[row]}${seat + 1}',
                      ),
                      onTap: () => onSeatTap('${rowLabels[row]}${seat + 1}'),
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
  final VoidCallback onTap;

  const _Seat({
    required this.id,
    required this.taken,
    required this.selected,
    required this.onTap,
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
          child: InkWell(
            onTap: taken ? null : onTap,
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
