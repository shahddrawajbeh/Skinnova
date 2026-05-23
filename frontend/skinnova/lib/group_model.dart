class GroupModel {
  final String id;
  final String title;
  final String slug;
  final String coverImage;
  final String profileImage;
  final String description;
  final String categoryKey;
  final int membersCount;
  final bool isActive;
  final String groupType;

  GroupModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.coverImage,
    required this.profileImage,
    required this.description,
    required this.categoryKey,
    required this.membersCount,
    required this.isActive,
    required this.groupType,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      coverImage: json['coverImage'] ?? '',
      profileImage: json['profileImage'] ?? '',
      description: json['description'] ?? '',
      categoryKey: json['categoryKey'] ?? '',
      membersCount: json['membersCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      groupType: json['groupType'] ?? '',
    );
  }
}
