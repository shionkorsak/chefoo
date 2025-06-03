import '../models/restaurant.dart';

class PlaceUtils {
  static String? getCrowdednessStatus(Place place) {
    if (place.popularTimes == null || !place.popularTimesLoaded || place.popularTimes!.isEmpty) {
      return null;
    }
    
    try {
      final now = DateTime.now();
      final currentDayIndex = now.weekday - 1;
      final currentHour = now.hour;
      
      if (currentDayIndex >= place.popularTimes!.length) {
        return null;
      }
      
      final dayData = place.popularTimes![currentDayIndex];
      final hourlyData = List<int>.from(dayData['data']);
      
      if (currentHour >= hourlyData.length) {
        return null;
      }
      
      final currentValue = hourlyData[currentHour];
      
      final maxValue = hourlyData.reduce((curr, next) => curr > next ? curr : next);
      
      if (maxValue == 0) {
        return "empty";
      }
      
      final percentOfMax = (currentValue / maxValue) * 100;
      
      if (percentOfMax < 30) {
        return "empty";
      } else if (percentOfMax < 70) {
        return "normal";
      } else {
        return "crowded";
      }
    } catch (e) {
      print('Error calculating crowdedness status: $e');
      return null;
    }
  }
}