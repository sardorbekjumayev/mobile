import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../data/models/exam_models.dart';

/// Renders a geometry/physics `figure` on its native 320×220 canvas with y
/// pointing down, scaled to the available width.
class FigureView extends StatelessWidget {
  const FigureView({super.key, required this.figure});

  final QuestionFigure figure;

  @override
  Widget build(BuildContext context) {
    if (figure.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: AppShapes.tileRadius,
      ),
      child: AspectRatio(
        aspectRatio: QuestionFigure.canvasWidth / QuestionFigure.canvasHeight,
        child: CustomPaint(painter: _FigurePainter(figure)),
      ),
    );
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter(this.figure);

  final QuestionFigure figure;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / QuestionFigure.canvasWidth;
    canvas.scale(scale);

    final stroke = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final line in figure.lines) {
      final from = Offset(line.x1, line.y1);
      final to = Offset(line.x2, line.y2);
      if (line.dashed) {
        _dashed(canvas, from, to, stroke);
      } else {
        canvas.drawLine(from, to, stroke);
      }
    }

    for (final circle in figure.circles) {
      canvas.drawCircle(Offset(circle.cx, circle.cy), circle.r, stroke);
    }

    for (final label in figure.labels) {
      final painter = TextPainter(
        text: TextSpan(
          text: label.text,
          style: const TextStyle(fontSize: 12, color: AppColors.body),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(label.x, label.y - painter.height / 2));
    }
  }

  /// A hidden edge — the fifth element of a line row set to `1`.
  void _dashed(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 6.0;
    const gap = 4.0;
    final delta = to - from;
    final length = delta.distance;
    if (length == 0) return;
    final step = delta / length;
    var travelled = 0.0;
    while (travelled < length) {
      final end = (travelled + dash).clamp(0.0, length);
      canvas.drawLine(from + step * travelled, from + step * end, paint);
      travelled = end + gap;
    }
  }

  @override
  bool shouldRepaint(_FigurePainter oldDelegate) => oldDelegate.figure != figure;
}
