class GroupPostModel {
  final String id;
  final String userName;
  final String userAvatar;
  final String tag;
  final String postType;
  final String content;
  final List<String> images;
  final String timeText;
  final bool isEdited;

  const GroupPostModel({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.tag,
    required this.postType,
    required this.content,
    required this.images,
    required this.timeText,
    this.isEdited = false,
  });

  factory GroupPostModel.fromJson(Map<String, dynamic> json) {
    return GroupPostModel(
      id: json['_id'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'] ?? '',
      tag: json['tag'] ?? '',
      postType: json['postType'] ?? 'update',
      content: json['content'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      timeText: json['timeText'] ?? 'Just now',
      isEdited: json['isEdited'] ?? false,
    );
  }
}
