class RestaurantRating {
  final double rating;
  final String feedback;
  final List<String> meal;
  final String? mealImageUrl;

  RestaurantRating({
    required this.rating,
    required this.feedback,
    required this.meal,
    this.mealImageUrl,
  });

  factory RestaurantRating.fromMap(Map<String, dynamic> map) =>
      RestaurantRating(
        rating: (map['rating'] as num).toDouble(),
        feedback: map['feedback'],
        meal: List<String>.from(map['meal']),
        mealImageUrl: map['mealImageUrl'],
      );

  Map<String, dynamic> toMap() => {
        'rating': rating,
        'feedback': feedback,
        'meal': meal,
        if (mealImageUrl != null) 'mealImageUrl': mealImageUrl,
      };
}

class Restaurant {
  final dynamic id;
  final String name;
  final String address;
  final RestaurantRating rating;
  final bool favorite;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.favorite,
  });

  factory Restaurant.fromMap(Map<String, dynamic> map) => Restaurant(
        id: map['id'],
        name: map['name'],
        address: map['address'],
        rating: RestaurantRating.fromMap(map['rating']),
        favorite: map['favorite'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'address': address,
        'rating': rating.toMap(),
        'favorite': favorite,
      };
}