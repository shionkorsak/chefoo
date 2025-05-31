import 'package:chefoo/commons.dart';
import 'package:flutter/material.dart';

class PopularTimesChart extends StatefulWidget {
  final List<Map<String, dynamic>> popularTimes;
  final List<String>? openingHours;

  const PopularTimesChart({
    Key? key,
    required this.popularTimes,
    this.openingHours,
  }) : super(key: key);

  @override
  State<PopularTimesChart> createState() => _PopularTimesChartState();
}

class _PopularTimesChartState extends State<PopularTimesChart> {
  int _currentDayIndex = DateTime.now().weekday - 1;

  int _convertTo24Hour(String time) {
    final isPM = time.toLowerCase().contains('pm');
    final hourMin = time.toLowerCase().replaceAll(' am', '').replaceAll(' pm', '').split(':');
    var hour = int.parse(hourMin[0]);
    
    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }
    
    return hour;
  }

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
    
    final String dayName = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][_currentDayIndex];
    final String? todayHours = widget.openingHours?.firstWhere(
      (hour) => hour.startsWith(dayName),
      orElse: () => '',
    );

    Widget buildChartContent() {
      // If closed or no hours available, show "Closed" message
      if (todayHours == null || todayHours.contains('Closed') || todayHours.isEmpty) {
        return Container(
          height: 150,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Closed on ${dayData['name']}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        );
      }

      // Parse opening hours for open days
      final timeRange = todayHours!.split(': ')[1];
      final times = timeRange.split('–');
      if (times.length != 2) {
        return const SizedBox.shrink();
      }

      final openHour = _convertTo24Hour(times[0].trim());
      final closeHour = _convertTo24Hour(times[1].trim());

      final startIndex = openHour.clamp(0, hourlyData.length - 1);
      final endIndex = closeHour.clamp(0, hourlyData.length - 1);
      final trimmedData = hourlyData.sublist(startIndex, endIndex + 1);

      return SizedBox(
        height: 150,
        child: CustomPaint(
          painter: _PopularTimesPainter(
            trimmedData,
            showAxis: true,
            startHour: openHour,
            endHour: closeHour,
          ),
          size: const Size(double.infinity, 150),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        buildChartContent(),
      ],
    );
  }
}

class _PopularTimesPainter extends CustomPainter {
  final List<int> hourlyData;
  final bool showAxis;
  final int startHour;
  final int endHour;

  _PopularTimesPainter(
    this.hourlyData, {
    this.showAxis = true,
    required this.startHour,
    required this.endHour,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPadding = 20;
    final double rightPadding = 20;

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;

    if (showAxis) {
      // Draw axes
      canvas.drawLine(
        Offset(leftPadding, 10),
        Offset(leftPadding, size.height - 20),
        axisPaint,
      );
      canvas.drawLine(
        Offset(leftPadding, size.height - 20),
        Offset(size.width - rightPadding, size.height - 20),
        axisPaint,
      );

      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      final hoursRange = endHour - startHour;
      
      // Calculate minimum step size to prevent label overlap
      // First, measure the width of a sample label
      textPainter.text = TextSpan(
        text: '00:00',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 10,
        ),
      );
      textPainter.layout();
      final labelWidth = textPainter.width + 10; // Add some padding
      
      // Calculate how many labels can fit without overlapping
      final availableWidth = size.width - leftPadding - rightPadding;
      final possibleLabels = (availableWidth / labelWidth).floor();
      final stepSize = ((hoursRange + 1) / possibleLabels).ceil();

      // Draw hour labels with calculated step size
      for (var hour = startHour; hour <= endHour; hour += stepSize) {
        textPainter.text = TextSpan(
          text: '${hour.toString().padLeft(2, '0')}:00',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        );
        textPainter.layout();

        final x = leftPadding + (hour - startHour) * availableWidth / hoursRange;
        textPainter.paint(
          canvas,
          Offset(
            x - textPainter.width / 2,
            size.height - 15,
          ),
        );
      }

      // Draw popularity data for opening hours only
      final width = availableWidth / hoursRange;
      final maxValue = hourlyData.reduce((curr, next) => curr > next ? curr : next).toDouble();
      final height = size.height - 30;

      final path = Path();
      path.moveTo(leftPadding, size.height - 20);

      for (var i = 0; i < hourlyData.length; i++) {
        final x = leftPadding + i * width;
        final y = size.height - 20 - (hourlyData[i] / maxValue * height);
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}