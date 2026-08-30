import 'package:free_map_review/models/review.dart';

enum Category { vegan, healthcare, general }

extension CategoryExtension on Category {
  String get value {
    switch (this) {
      case Category.vegan:
        return 'vegan';
      case Category.healthcare:
        return 'healthcare';
      case Category.general:
        return 'general';
    }
  }

  static Category fromString(String value) {
    switch (value) {
      case 'vegan':
        return Category.vegan;
      case 'healthcare':
        return Category.healthcare;
      default:
        return Category.general;
    }
  }

  String get label {
    switch (this) {
      case Category.vegan:
        return 'Vegan';
      case Category.healthcare:
        return 'Healthcare';
      case Category.general:
        return 'Generale';
    }
  }

  String get iconAsset {
    switch (this) {
      case Category.vegan:
        return 'assets/icons/vegan.png';
      case Category.healthcare:
        return 'assets/icons/healthcare.png';
      case Category.general:
        return 'assets/icons/general.png';
    }
  }
}

class Location {
  final String id;
  final String name;
  final String? description;
  final double lat;
  final double lng;
  final Category category;
  final bool isVerified;
  final DateTime createdAt;
  final String userId;
  final List<Review>? reviews;

  const Location({
    required this.id,
    required this.name,
    this.description,
    required this.lat,
    required this.lng,
    required this.category,
    this.isVerified = false,
    required this.createdAt,
    required this.userId,
    this.reviews,
  });

  factory Location.fromJson(Map<String, dynamic> json, {List<Review>? reviews}) {
    return Location(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      category: CategoryExtension.fromString(json['category'] as String),
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
      reviews: reviews,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'lat': lat,
      'lng': lng,
      'category': category.value,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
    };
  }

  double get averageRating {
    if (reviews == null || reviews!.isEmpty) return 0.0;
    final sum = reviews!.fold<int>(0, (a, b) => a + b.rating);
    return sum / reviews!.length;
  }

  int get reviewCount => reviews?.length ?? 0;
}
