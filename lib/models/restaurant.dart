class Place {
  final String id;
  final String name;
  final double rating;
  final String address;
  final double distance;
  final List<String> tags;
  final String? phone;
  final List<String>? openingHours;
  final List<Review> reviews;
  final List<String> pictureUrls;
  final double lat;
  final double lng;

  Place({
    required this.id,
    required this.name,
    required this.rating,
    required this.address,
    required this.distance,
    required this.tags,
    this.phone,
    this.openingHours,
    required this.reviews,
    required this.pictureUrls,
    required this.lat,
    required this.lng,
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
      openingHours: (json['opening_hours'] as List?)?.cast<String>(),
      reviews: (json['reviews'] as List)
          .map((reviewJson) => Review.fromJson(reviewJson))
          .toList(),
      pictureUrls: (json['pictures'] as List).cast<String>(),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  factory Place.fromGooglePlace(Map<String, dynamic> place, Map<String, dynamic> details) {
    return Place(
      id: place['place_id'] as String,
      name: place['name'] as String,
      rating: (place['rating'] ?? 0.0) as double,
      address: place['vicinity'] as String,
      distance: 0.0, // We'll implement this later with GPS
      tags: [],
      phone: details['formatted_phone_number'] as String?,
      openingHours: details['opening_hours']?['weekday_text']?.cast<String>(),
      reviews: (details['reviews'] as List?)
          ?.map((r) => Review.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      pictureUrls: (place['photos'] as List?)
          ?.map((p) => p['photo_reference'] as String)
          .toList() ?? [],
      lat: place['geometry']['location']['lat'] as double,
      lng: place['geometry']['location']['lng'] as double,
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
      'opening_hours': openingHours,
      'reviews': reviews.map((review) => review.toJson()).toList(),
      'pictures': pictureUrls,
      'lat': lat,
      'lng': lng,
    };
  }
}

class Review {
  final String authorName;
  final double rating;
  final String text;
  final String? time;

  Review({
    required this.authorName,
    required this.rating,
    required this.text,
    this.time,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      authorName: json['author_name'] as String,
      rating: (json['rating'] as num).toDouble(),
      text: json['text'] as String,
      time: json['time']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author_name': authorName,
      'rating': rating,
      'text': text,
      'time': time,
    };
  }
}
