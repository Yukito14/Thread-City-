class AppNotification {
  final int id;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final NotificationActor actor;
  final NotificationPost? post;

  AppNotification({
    required this.id,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.actor,
    this.post,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? 0,
      type: map['type']?.toString() ?? '',
      isRead: map['is_read'] == true,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      actor: NotificationActor.fromMap(
        Map<String, dynamic>.from(map['actor'] ?? {}),
      ),
      post: map['post'] != null
          ? NotificationPost.fromMap(
        Map<String, dynamic>.from(map['post']),
      )
          : null,
    );
  }

  String get actionText {
    switch (type) {
      case 'like':
        return 'đã thích bài viết của bạn';
      case 'reply':
        return 'đã trả lời bài viết của bạn';
      case 'follow':
        return 'đã bắt đầu theo dõi bạn';
      case 'repost':
        return 'đã chia sẻ lại bài viết của bạn';
      case 'mention':
        return 'đã nhắc đến bạn';
      default:
        return 'đã tương tác với bạn';
    }
  }

  String get previewText {
    return post?.content ?? '';
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return 'vừa xong';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours} giờ';
    }

    if (diff.inDays < 7) {
      return '${diff.inDays} ngày';
    }

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

class NotificationActor {
  final int id;
  final String username;
  final String? nickname;
  final String? avatarUrl;
  final bool isVerified;

  NotificationActor({
    required this.id,
    required this.username,
    this.nickname,
    this.avatarUrl,
    required this.isVerified,
  });

  factory NotificationActor.fromMap(Map<String, dynamic> map) {
    return NotificationActor(
      id: map['id'] ?? 0,
      username: map['username']?.toString() ?? '',
      nickname: map['nickname']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      isVerified: map['is_verified'] == true,
    );
  }

  String get displayName {
    if (nickname != null && nickname!.isNotEmpty) {
      return nickname!;
    }

    return username;
  }

  String get initials {
    if (displayName.trim().isEmpty) {
      return '?';
    }

    final parts = displayName.trim().split(' ');

    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }

    return displayName[0].toUpperCase();
  }
}

class NotificationPost {
  final int id;
  final String content;

  NotificationPost({
    required this.id,
    required this.content,
  });

  factory NotificationPost.fromMap(Map<String, dynamic> map) {
    return NotificationPost(
      id: map['id'] ?? 0,
      content: map['content']?.toString() ?? '',
    );
  }
}