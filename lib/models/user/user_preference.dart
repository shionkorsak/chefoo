class UserPreference {
  final List<String> description;
  final List<String> likedFood;
  final List<String> dislikedFood;
  final List<String> cuisine;
  final List<String> dietaryPreferences;
  final List<String> allergies;

  UserPreference({
    required this.description,
    required this.likedFood,
    required this.dislikedFood,
    required this.cuisine,
    required this.dietaryPreferences,
    required this.allergies,
  });

  factory UserPreference.fromMap(Map<String, dynamic> map) => UserPreference(
        description: List<String>.from(map['description']),
        likedFood: List<String>.from(map['likedFood']),
        dislikedFood: List<String>.from(map['dislikedFood']),
        cuisine: List<String>.from(map['cuisine']),
        dietaryPreferences: List<String>.from(map['dietaryPreferences']),
        allergies: List<String>.from(map['allergies']),
      );

  Map<String, dynamic> toMap() => {
        'description': description,
        'likedFood': likedFood,
        'dislikedFood': dislikedFood,
        'cuisine': cuisine,
        'dietaryPreferences': dietaryPreferences,
        'allergies': allergies,
      };
}
