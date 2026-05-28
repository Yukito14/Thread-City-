class UserModel {
  final int id;
  final String firebaseUid;
  final String username;
  final String email;
  final String? nickname;
  final String? bio;
  final String? avatarUrl;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.firebaseUid,
    required this.username,
    required this.email,
    this.nickname,
    this.bio,
    this.avatarUrl,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] is int
          ? map['id']
          : int.tryParse(map['id'].toString()) ?? 0,
      firebaseUid: map['firebase_uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      nickname: map['nickname'],
      bio: map['bio'],
      avatarUrl: map['avatar_url'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'username': username,
      'email': email,
      'nickname': nickname,
      'bio': bio,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}