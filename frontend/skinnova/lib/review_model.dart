class ReviewModel {
  final String userId;
  final String userName;
  final double rating;
  final String title;
  final String comment;
  final bool? repurchase;
  final bool? improvedSkin;
  final bool? wasGift;
  final bool? adverseReaction;
  final String texture;
  final String usageWeeks;
  final DateTime? createdAt;

  ReviewModel({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.title,
    required this.comment,
    this.repurchase,
    this.improvedSkin,
    this.wasGift,
    this.adverseReaction,
    required this.texture,
    required this.usageWeeks,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      title: json['title'] ?? '',
      comment: json['comment'] ?? '',
      repurchase: json['repurchase'],
      improvedSkin: json['improvedSkin'],
      wasGift: json['wasGift'],
      adverseReaction: json['adverseReaction'],
      texture: json['texture'] ?? '',
      usageWeeks: json['usageWeeks'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'title': title,
      'comment': comment,
      'repurchase': repurchase,
      'improvedSkin': improvedSkin,
      'wasGift': wasGift,
      'adverseReaction': adverseReaction,
      'texture': texture,
      'usageWeeks': usageWeeks,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
