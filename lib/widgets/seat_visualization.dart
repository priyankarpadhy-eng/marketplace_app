import 'package:flutter/material.dart';

class SeatVisualization extends StatelessWidget {
  final int totalSeats;
  final int seatsTaken;

  const SeatVisualization({
    super.key,
    required this.totalSeats,
    required this.seatsTaken,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTotal = totalSeats.clamp(1, 6);
    final effectiveTaken = seatsTaken.clamp(0, effectiveTotal);

    return Row(
      children: List.generate(effectiveTotal, (index) {
        final filled = index < effectiveTaken;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            Icons.event_seat_rounded,
            size: 18,
            color: filled
                ? Colors.redAccent
                : Colors.greenAccent,
          ),
        );
      }),
    );
  }
}

