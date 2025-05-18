class HealthInsight {
  final double healthScore;
  final List<WeeklyData> weeklyData;

  HealthInsight({required this.healthScore, required this.weeklyData});

  factory HealthInsight.fromMap(Map<String, dynamic> map) {
    return HealthInsight(
      healthScore: (map['healthScore'] ?? 0).toDouble(),
      weeklyData: (map['weeklyData'] as List<dynamic>? ?? [])
          .map((e) => WeeklyData.fromMap(Map<String, dynamic>.from(e ?? {})))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'healthScore': healthScore,
        'weeklyData': weeklyData.map((e) => e.toMap()).toList(),
      };
}

class WeeklyData {
  final int week;
  final double ratio;
  final String comment;

  WeeklyData({required this.week, required this.ratio, required this.comment});

  factory WeeklyData.fromMap(Map<String, dynamic> map) {
    return WeeklyData(
      week: map['week'] is int ? map['week'] as int : 0,
      ratio: (map['ratio'] is num) ? (map['ratio'] as num).toDouble() : 0.0,
      comment: map['comment'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'week': week,
        'ratio': ratio,
        'comment': comment,
      };
}