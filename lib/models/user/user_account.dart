import 'user_profile.dart';
import 'user_preference.dart';
import 'health_insight.dart';
import 'restaurant.dart';

class UserAccount {
  final UserProfile profile;
  final UserPreference preferences;
  final HealthInsight healthInsight;
  final List<Restaurant> restaurantHistory;
  final List<Restaurant> favoriteRestaurant;

  UserAccount({
    required this.profile,
    required this.preferences,
    required this.healthInsight,
    required this.restaurantHistory,
    required this.favoriteRestaurant,
  });

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      profile: UserProfile.fromMap(Map<String, dynamic>.from(map['profile'] ?? {})),
      preferences: UserPreference.fromMap(Map<String, dynamic>.from(map['preferences'] ?? {})),
      healthInsight: HealthInsight.fromMap(Map<String, dynamic>.from(map['healthInsights'] ?? {})),
      restaurantHistory: (map['restaurantHistory'] as List<dynamic>? ?? [])
          .map((e) => Restaurant.fromMap(Map<String, dynamic>.from(e ?? {})))
          .toList(),
      favoriteRestaurant: (map['favoriteRestaurant'] as List<dynamic>? ?? [])
          .map((e) => Restaurant.fromMap(Map<String, dynamic>.from(e ?? {})))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'profile': profile.toMap(),
        'preferences': preferences.toMap(),
        'healthInsight': healthInsight.toMap(),
        'restaurantHistory': restaurantHistory.map((e) => e.toMap()).toList(),
        'favoriteRestaurant':
            favoriteRestaurant.map((e) => e.toMap()).toList(),
      };
}
