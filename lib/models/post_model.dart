class PostModel {
  final int id;
  final String authorName;
  final String authorUsername;
  final String authorAvatar;
  final bool verified;
  final String content;
  final String? imageUrl;
  final int likes;
  final int replies;
  final int reposts;
  final String timeAgo;

  const PostModel({
    required this.id,
    required this.authorName,
    required this.authorUsername,
    required this.authorAvatar,
    required this.verified,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.replies,
    required this.reposts,
    required this.timeAgo,
  });
}