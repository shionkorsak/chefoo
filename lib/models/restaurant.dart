class Place {
  final String id;
  final String name;
  final double rating;
  final String address;
  final double distance; 
  final List<String> tags;
  final String? phone;
  final List<String> pictureUrls;
  final List<Review> reviews;
  final List<String>? openingHours;

  Place({
    required this.id,
    required this.name,
    required this.rating,
    required this.address,
    required this.distance,
    required this.tags,
    this.phone,
    required this.pictureUrls,
    required this.reviews,
    this.openingHours,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      rating: (json['rating'] as num).toDouble(),
      address: json['address'] as String,
      distance: (json['distance'] as num).toDouble(),
      tags: (json['tags'] as List).cast<String>(),
      phone: json['phone'] as String?,
      pictureUrls: (json['pictures'] as List).cast<String>(),
      reviews: (json['reviews'] as List)
          .map((reviewJson) => Review.fromJson(reviewJson))
          .toList(),
      openingHours: (json['opening_hours'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'address': address,
      'distance': distance,
      'tags': tags,
      'phone': phone,
      'pictures': pictureUrls,
      'reviews': reviews.map((review) => review.toJson()).toList(),
      'opening_hours': openingHours,
    };
  }
}

class Review {
  final String id;
  final String authorName;
  final double rating;
  final String text;
  final DateTime timestamp;

  Review({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.text,
    required this.timestamp,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      authorName: json['author_name'] as String,
      rating: (json['rating'] as num).toDouble(),
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_name': authorName,
      'rating': rating,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
