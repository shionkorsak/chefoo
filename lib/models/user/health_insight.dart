class HealthInsight {
  final double healthScore;
  final List<DailyHealthData> weeklyData;

  HealthInsight({required this.healthScore, required this.weeklyData});

  factory HealthInsight.fromMap(Map<String, dynamic> map) {
    return HealthInsight(
      healthScore: (map['healthScore'] ?? 0).toDouble(),
      weeklyData: (map['weeklyData'] as List<dynamic>? ?? [])
          .map((e) => DailyHealthData.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'healthScore': healthScore,
        'weeklyData': weeklyData.map((e) => e.toMap()).toList(),
      };
}

class DailyHealthData {
  final String date;
  final List<Map<String, dynamic>> mealInput; // raw meal maps
  final int ratio;
  final String comment;

  DailyHealthData({
    required this.date,
    required this.mealInput,
    required this.ratio,
    required this.comment,
  });

  factory DailyHealthData.fromMap(Map<String, dynamic> map) {
    return DailyHealthData(
      date: map['date'] as String,
      mealInput: (map['mealInput'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      ratio: (map['ratio'] as num).toInt(),
      comment: map['comment'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date,
        'mealInput': mealInput,
        'ratio': ratio,
        'comment': comment,
      };
}
