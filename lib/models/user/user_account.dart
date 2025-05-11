import 'user_profile.dart';
import 'user_preference.dart';
import 'health_insight.dart';
import 'restaurant.dart';

class UserAccount {
  final UserProfile profile;
  final UserPreference preferences;
  final HealthInsight healthInsight;

  UserAccount({
    required this.profile,
    required this.preferences,
    required this.healthInsight,
  });

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      profile: UserProfile.fromMap(Map<String, dynamic>.from(map['profile'] ?? {})),
      preferences: UserPreference.fromMap(Map<String, dynamic>.from(map['preferences'] ?? {})),
      healthInsight: HealthInsight.fromMap(Map<String, dynamic>.from(map['healthInsights'] ?? {})),
    );
  }

  Map<String, dynamic> toMap() => {
        'profile': profile.toMap(),
        'preferences': preferences.toMap(),
        'healthInsight': healthInsight.toMap(),
      };
}
