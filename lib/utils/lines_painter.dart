import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class LinesPainter extends CustomPainter {
  final Offset tower1;
  final Offset tower2;
  final Offset tower3;
  final Offset userCoords;

  LinesPainter(this.tower1, this.tower2, this.tower3, this.userCoords);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Рисуем линии между башнями
    canvas.drawLine(tower1, tower2, paint);
    canvas.drawLine(tower2, tower3, paint);
    canvas.drawLine(tower3, tower1, paint);

    // Рисуем пунктирные линии от башен к пользователю
    final dashPaint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final shader = LinearGradient(
      colors: [Colors.blue, Colors.red],
    ).createShader(Rect.fromPoints(tower1, userCoords));

    dashPaint.shader = shader;

    _drawDashedLine(canvas, tower1, userCoords, dashPaint);
    _drawDashedLine(canvas, tower2, userCoords, dashPaint);
    _drawDashedLine(canvas, tower3, userCoords, dashPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final double dashWidth = 5.0;
    final double dashSpace = 5.0;
    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double length = sqrt(dx * dx + dy * dy);
    final double dashCount = (length ~/ (dashWidth + dashSpace)) as double;
    final double remainingLength = length - dashCount * (dashWidth + dashSpace);

    for (int i = 0; i < dashCount; i++) {
      final double t0 = (i * (dashWidth + dashSpace)) / length;
      final double t1 = (i * (dashWidth + dashSpace) + dashWidth) / length;
      final Offset p0 = Offset(start.dx + dx * t0, start.dy + dy * t0);
      final Offset p1 = Offset(start.dx + dx * t1, start.dy + dy * t1);
      canvas.drawLine(p0, p1, paint);
    }

    if (remainingLength > 0) {
      final double t0 = (dashCount * (dashWidth + dashSpace)) / length;
      final Offset p0 = Offset(start.dx + dx * t0, start.dy + dy * t0);
      canvas.drawLine(p0, end, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}