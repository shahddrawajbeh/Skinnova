class OnboardingModel {
  final List<String> skinConcerns;
  final List<String> goals;
  final List<String> specialConditions;
  final String gender;
  final String ageRange;
  final String skinType;
  final String skinSensitivity;
  final String skinPhototype;
  final String skincareExperience;
  final String chronicCondition;

  OnboardingModel({
    required this.skinConcerns,
    required this.goals,
    required this.specialConditions,
    required this.gender,
    required this.ageRange,
    required this.skinType,
    required this.skinSensitivity,
    required this.skinPhototype,
    required this.skincareExperience,
    required this.chronicCondition,
  });

  factory OnboardingModel.fromJson(Map<String, dynamic> json) {
    return OnboardingModel(
      skinConcerns: List<String>.from(json['skinConcerns'] ?? []),
      goals: List<String>.from(json['goals'] ?? []),
      specialConditions: List<String>.from(json['specialConditions'] ?? []),
      gender: json['gender'] ?? '',
      ageRange: json['ageRange'] ?? '',
      skinType: json['skinType'] ?? '',
      skinSensitivity: json['skinSensitivity'] ?? '',
      skinPhototype: json['skinPhototype'] ?? '',
      skincareExperience: json['skincareExperience'] ?? '',
      chronicCondition: json['chronicCondition'] ?? '',
    );
  }
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final OnboardingModel onboarding;
  final String? profileImage;
  final String bio;
  final String city;
  final List<UserCollectionModel> collections;
  final List<FavoriteProductModel> favorites;
  final List<FollowUserModel> followers;
  final List<FollowUserModel> following;
  final List<FavoriteProductModel> recentlyUsedProducts;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.onboarding,
    this.profileImage,
    this.bio = '',
    this.city = '',
    required this.collections,
    this.favorites = const [],
    required this.followers,
    required this.following,
    this.recentlyUsedProducts = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      onboarding: OnboardingModel.fromJson(json['onboarding'] ?? {}),
      profileImage: json['profileImage'],
      bio: json['bio'] ?? '',
      city: json['city'] ?? '',
      collections: (json['collections'] as List<dynamic>?)
              ?.map((e) => UserCollectionModel.fromJson(e))
              .toList() ??
          [],
      favorites: (json['favorites'] as List<dynamic>?)
              ?.map((e) => FavoriteProductModel.fromJson(e))
              .toList() ??
          [],
      followers: (json['followers'] as List? ?? [])
          .map((e) => FollowUserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      following: (json['following'] as List? ?? [])
          .map((e) => FollowUserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      recentlyUsedProducts: (json['recentlyUsedProducts'] as List<dynamic>?)
              ?.map((e) => FavoriteProductModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class UserCollectionModel {
  final String id;
  final String title;
  final List<String> images;

  UserCollectionModel({
    required this.id,
    required this.title,
    required this.images,
  });

  factory UserCollectionModel.fromJson(Map<String, dynamic> json) {
    return UserCollectionModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class FavoriteProductModel {
  final String id;
  final String name;
  final String brand;
  final String imageUrl;
  //final String category;
  final double rating;

  FavoriteProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.imageUrl,
    //required this.category,
    required this.rating,
  });

  factory FavoriteProductModel.fromJson(Map<String, dynamic> json) {
    return FavoriteProductModel(
      id: json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      //category: json['category'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }
}

class FollowUserModel {
  final String id;
  final String fullName;
  final String profileImage;

  FollowUserModel({
    required this.id,
    required this.fullName,
    required this.profileImage,
  });

  factory FollowUserModel.fromJson(Map<String, dynamic> json) {
    return FollowUserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      profileImage: json['profileImage'] ?? '',
    );
  }
}
