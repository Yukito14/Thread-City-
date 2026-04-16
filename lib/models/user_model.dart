class UserModel {
  final String username;
  final String nickname;
  final String email;
  final String avatarUrl;
  final int followingCount;
  final int followersCount;

  const UserModel({
    required this.username,
    required this.nickname,
    required this.email,
    required this.avatarUrl,
    required this.followingCount,
    required this.followersCount,
  });
}