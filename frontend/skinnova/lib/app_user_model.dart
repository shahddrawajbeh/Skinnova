class AppUserModel {
  final String id;
  final String fullName;
  final String email;
  final String profileImage;
  final String skinType;

  AppUserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.profileImage,
    required this.skinType,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'] ?? '',
      skinType: json['onboarding']?['skinType'] ?? '',
    );
  }
}
