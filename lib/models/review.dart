class Review {
  final String id;
  final String locationId;
  final int rating;
  final String? reviewText;
  final String? categoryDetail;
  final List<String> images;
  final bool isAnonymous;
  final DateTime createdAt;
  final String? userName;

  const Review({
    required this.id,
    required this.locationId,
    required this.rating,
    this.reviewText,
    this.categoryDetail,
    this.images = const [],
    this.isAnonymous = true,
    required this.createdAt,
    this.userName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final imagesList = json['images'] as List<dynamic>?;
    return Review(
      id: json['id'] as String,
      locationId: json['location_id'] as String,
      rating: json['rating'] as int,
      reviewText: json['review_text'] as String?,
      categoryDetail: json['category_detail'] as String?,
      images: imagesList?.map((e) => e as String).toList() ?? [],
      isAnonymous: json['is_anonymous'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['user_profiles']?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_id': locationId,
      'rating': rating,
      'review_text': reviewText,
      'category_detail': categoryDetail,
      'images': images,
      'is_anonymous': isAnonymous,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class HealthcareReviewFields {
  final bool hasVisited;
  final int cleanliness;
  final int personalAttention;
  final int waitingTime;

  const HealthcareReviewFields({
    required this.hasVisited,
    required this.cleanliness,
    required this.personalAttention,
    required this.waitingTime,
  });

  Map<String, dynamic> toJson() => {
        'has_visited': hasVisited,
        'cleanliness': cleanliness,
        'personal_attention': personalAttention,
        'waiting_time': waitingTime,
      };

  factory HealthcareReviewFields.fromJson(Map<String, dynamic> json) {
    return HealthcareReviewFields(
      hasVisited: json['has_visited'] as bool? ?? false,
      cleanliness: json['cleanliness'] as int? ?? 0,
      personalAttention: json['personal_attention'] as int? ?? 0,
      waitingTime: json['waiting_time'] as int? ?? 0,
    );
  }
}
