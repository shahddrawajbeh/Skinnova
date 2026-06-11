/// A recent group-join by someone the current user follows.
class FriendActivityModel {
  final String friendId;
  final String friendName;
  final String friendAvatar;
  final String groupSlug;
  final String groupTitle;
  final DateTime? activityAt;
  final int newPostsCount;

  const FriendActivityModel({
    required this.friendId,
    required this.friendName,
    required this.friendAvatar,
    required this.groupSlug,
    required this.groupTitle,
    this.activityAt,
    this.newPostsCount = 0,
  });

  factory FriendActivityModel.fromJson(Map<String, dynamic> json) {
    return FriendActivityModel(
      friendId: json['friendId'] ?? '',
      friendName: json['friendName'] ?? '',
      friendAvatar: json['friendAvatar'] ?? '',
      groupSlug: json['groupSlug'] ?? '',
      groupTitle: json['groupTitle'] ?? '',
      activityAt: json['activityAt'] != null
          ? DateTime.tryParse(json['activityAt'])
          : null,
      newPostsCount: json['newPostsCount'] ?? 0,
    );
  }
}
