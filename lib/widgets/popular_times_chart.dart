import 'package:flutter/material.dart';

class PopularTimesChart extends StatefulWidget {
  final List<Map<String, dynamic>> popularTimes;

  const PopularTimesChart({
    Key? key,
    required this.popularTimes,
  }) : super(key: key);

  @override
  State<PopularTimesChart> createState() => _PopularTimesChartState();
}

class _PopularTimesChartState extends State<PopularTimesChart> {
  int _currentDayIndex = DateTime.now().weekday - 1;

  void _previousDay() {
    setState(() {
      _currentDayIndex = (_currentDayIndex - 1 + 7) % 7;
    });
  }

  void _nextDay() {
    setState(() {
      _currentDayIndex = (_currentDayIndex + 1) % 7;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayData = widget.popularTimes[_currentDayIndex];
    final List<int> hourlyData = List<int>.from(dayData['data']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Times',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _previousDay,
              iconSize: 16,
            ),
            Text(
              _currentDayIndex == DateTime.now().weekday - 1 
                ? 'Today' 
                : dayData['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _nextDay,
              iconSize: 16,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: CustomPaint(
            painter: _PopularTimesPainter(
              hourlyData,
              showAxis: true,
              openingHour: 6,
              closingHour: 22,
            ),
            size: const Size(double.infinity, 150),
          ),
        ),
      ],
    );
  }
}

class _PopularTimesPainter extends CustomPainter {
  final List<int> hourlyData;
  final bool showAxis;
  final int openingHour;
  final int closingHour;

  _PopularTimesPainter(
    this.hourlyData, {
    this.showAxis = true,
    this.openingHour = 6,
    this.closingHour = 22,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;

    if (showAxis) {
      canvas.drawLine(
        Offset(40, 10),
        Offset(40, size.height - 20),
        axisPaint,
      );

      canvas.drawLine(
        Offset(40, size.height - 20),
        Offset(size.width - 10, size.height - 20),
        axisPaint,
      );

      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      for (var hour = openingHour; hour <= closingHour; hour += 3) {
        final text = hour.toString();
        textPainter.text = TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            40 + (hour - openingHour) * (size.width - 50) / (closingHour - openingHour) - textPainter.width / 2,
            size.height - 15,
          ),
        );
      }
    }

    final width = (size.width - 50) / hourlyData.length;
    final maxValue = hourlyData.reduce((curr, next) => curr > next ? curr : next).toDouble();
    final height = size.height - 30;

    Path path = Path();
    path.moveTo(40, size.height - 20);

    for (var i = 0; i < hourlyData.length; i++) {
      final x = 40 + i * width;
      final y = size.height - 20 - (hourlyData[i] / maxValue * height);
      
      if (i == 0) {
        path.moveTo(x, size.height - 20);
      }
      path.lineTo(x, y);
    }

    path.lineTo(40 + (hourlyData.length - 1) * width, size.height - 20);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}