import 'health_insight.dart';
import 'user_preference.dart';
import 'user_profile.dart';

class UserAccount {
  final UserProfile? profile;
  final UserPreference? preferences;
  final HealthInsight? healthInsight;

  UserAccount({
    required this.profile,
    required this.preferences,
    required this.healthInsight,
  });

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      profile: map['profile'] != null ? UserProfile.fromMap(map['profile']) : null,
      preferences: map['preferences'] != null ? UserPreference.fromMap(map['preferences']) : null,
      healthInsight: map['healthInsight'] != null
          ? HealthInsight.fromMap(Map<String, dynamic>.from(map['healthInsight']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (profile != null) 'profile': profile!.toMap(),
      if (preferences != null) 'preferences': preferences!.toMap(),
      if (healthInsight != null) 'healthInsight': healthInsight!.toMap(),
    };
  }
}
