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

/// A group the current user has joined, annotated with whether
/// it has had any new posts in the last 24 hours.
class MyGroupModel extends GroupModel {
  final bool hasNewActivity;

  MyGroupModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.coverImage,
    required super.profileImage,
    required super.description,
    required super.categoryKey,
    required super.membersCount,
    required super.isActive,
    required super.groupType,
    required this.hasNewActivity,
  });

  factory MyGroupModel.fromJson(Map<String, dynamic> json) {
    final base = GroupModel.fromJson(json);
    return MyGroupModel(
      id: base.id,
      title: base.title,
      slug: base.slug,
      coverImage: base.coverImage,
      profileImage: base.profileImage,
      description: base.description,
      categoryKey: base.categoryKey,
      membersCount: base.membersCount,
      isActive: base.isActive,
      groupType: base.groupType,
      hasNewActivity: json['hasNewActivity'] ?? false,
    );
  }
}

/// A member of a group, with follow-relationship info relative to
/// the requesting user.
class GroupMemberModel {
  final String id;
  final String fullName;
  final String profileImage;
  final DateTime? joinedAt;
  final bool isFollowedByMe;
  final bool isMutual;

  GroupMemberModel({
    required this.id,
    required this.fullName,
    required this.profileImage,
    this.joinedAt,
    this.isFollowedByMe = false,
    this.isMutual = false,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      profileImage: json['profileImage'] ?? '',
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'])
          : null,
      isFollowedByMe: json['isFollowedByMe'] ?? false,
      isMutual: json['isMutual'] ?? false,
    );
  }
}
