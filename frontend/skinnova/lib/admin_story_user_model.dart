class AdminStoryUserModel {
  final String id;
  final String fullName;
  final String profileImage;

  AdminStoryUserModel({
    required this.id,
    required this.fullName,
    required this.profileImage,
  });

  factory AdminStoryUserModel.fromJson(Map<String, dynamic> json) {
    return AdminStoryUserModel(
      id: json['_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      profileImage: json['profileImage']?.toString() ?? '',
    );
  }
}
