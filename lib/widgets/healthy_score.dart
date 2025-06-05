import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/cards/auth_card.dart';

class HealthyScore extends StatelessWidget {
  final int score;

  const HealthyScore({Key? key, this.score = 79}) : super(key: key);

  Color get scoreColor {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.yellow;
    return Colors.red;
  }

  String get feedbackMessage {
    if (score >= 80) return "Great! Your score looks healthy!";
    if (score >= 50) return "Not bad! Let's aim for higher score.";
    return "Take care! Consider healthier options.";
  }

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      margin: EdgeInsets.zero,
      children: [
        Text(
          "Healthy Score",
          style: AppTextStyles.headline2.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        AspectRatio(
          aspectRatio: 2,
          child: CustomPaint(
            painter: _HalfDonutPainter(score: score),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  '$score',
                  style: AppTextStyles.headline1.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          feedbackMessage,
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _HalfDonutPainter extends CustomPainter {
  final int score;
  _HalfDonutPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2.4;
    final Offset center = Offset(size.width / 2, size.height);
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius - 7);

    final Paint bgPaint = Paint()
      ..color = AppColors.surface.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    final Paint fgPaint = Paint()
      ..color = _getColorForScore(score)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    // Draw background arc
    canvas.drawArc(arcRect, pi, pi, false, bgPaint);

    // Draw score arc
    double sweepAngle = pi * (score / 100).clamp(0.0, 1.0);
    double startAngle = pi;

    canvas.drawArc(arcRect, pi, sweepAngle, false, fgPaint);

    // Draw tick arcs
    final Paint tickPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    const int markCount = 20;
    for (int i = 0; i < markCount; i++) {
      double start = pi + (pi * i / markCount);
      double sweep = pi / markCount / 2;

      canvas.drawArc(
        arcRect.inflate(23),
        start,
        sweep,
        false,
        tickPaint,
      );
    }

    // Outer arc segments with color
    final Rect outerArc = arcRect.inflate(23);

    final Paint redArc = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final Paint yellowArc = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final Paint greenArc = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Draw red 0-40
    canvas.drawArc(outerArc, pi, pi * 0.4, false, redArc);
    // Draw yellow 40-70
    canvas.drawArc(outerArc, pi + pi * 0.4, pi * 0.3, false, yellowArc);
    // Draw green 70-100
    canvas.drawArc(outerArc, pi + pi * 0.7, pi * 0.3, false, greenArc);
  }

  Color _getColorForScore(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.yellow;
    return Colors.red;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}