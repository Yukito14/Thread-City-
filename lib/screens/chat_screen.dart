import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/post_provider.dart';
import 'post_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final Map<String, dynamic> otherUser;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;

  String? get _currentUid =>
      context.read<AuthProvider>().currentUserData?['firebase_uid'];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = _currentUid;
      if (uid != null) {
        final messageProvider = context.read<MessageProvider>();

        messageProvider.connectSocket(uid);
        messageProvider.joinConversation(widget.conversationId);

        await messageProvider.loadMessages(
          conversationId: widget.conversationId,
          firebaseUid: uid,
        );

        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    final uid = _currentUid;

    if (uid != null) {
      context.read<MessageProvider>().emitStopTyping(
        conversationId: widget.conversationId,
        firebaseUid: uid,
      );
    }

    context.read<MessageProvider>().leaveConversation(widget.conversationId);
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final uid = _currentUid;
    final text = _messageController.text.trim();

    if (uid == null || text.isEmpty) return;

    _typingTimer?.cancel();

    context.read<MessageProvider>().emitStopTyping(
      conversationId: widget.conversationId,
      firebaseUid: uid,
    );

    _messageController.clear();

    await context.read<MessageProvider>().sendMessage(
      conversationId: widget.conversationId,
      firebaseUid: uid,
      content: text,
    );

    _scrollToBottom();
  }

  void _handleTypingChanged(String value) {
    final uid = _currentUid;
    if (uid == null) return;

    final provider = context.read<MessageProvider>();

    if (value.trim().isNotEmpty) {
      provider.emitTyping(
        conversationId: widget.conversationId,
        firebaseUid: uid,
      );

      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(milliseconds: 900), () {
        provider.emitStopTyping(
          conversationId: widget.conversationId,
          firebaseUid: uid,
        );
      });
    } else {
      _typingTimer?.cancel();

      provider.emitStopTyping(
        conversationId: widget.conversationId,
        firebaseUid: uid,
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.otherUser['username'] ?? 'user';
    final nickname = widget.otherUser['nickname'];
    final avatarUrl = widget.otherUser['avatar_url'];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            _ChatAvatar(username: username, avatarUrl: avatarUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (nickname != null &&
                      nickname.toString().trim().isNotEmpty &&
                      nickname != username)
                    Text(
                      nickname.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.textPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingMessages && provider.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.textPrimary,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (provider.messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Hãy bắt đầu cuộc trò chuyện.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                final reversedMessages = provider.messages.reversed.toList();
                final hasTyping = provider.isOtherUserTyping;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: reversedMessages.length + (hasTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (hasTyping && index == 0) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: _TypingBubble(),
                      );
                    }

                    final messageIndex = hasTyping ? index - 1 : index;
                    final message = reversedMessages[messageIndex];
                    final sender = message['sender'] ?? {};
                    final senderUid = sender['firebase_uid'];
                    final currentUid = _currentUid;
                    final isMe = senderUid == currentUid;

                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: _handleTypingChanged,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhắn tin...',
                        hintStyle: const TextStyle(
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: AppColors.surface,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Message Bubble
// ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final content = (message['content'] ?? '').toString();
    final sharedPost = _SharedPostPayload.tryParse(content);

    if (sharedPost != null) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76,
          ),
          child: Column(
            crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (sharedPost.note.trim().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.textPrimary
                        : AppColors.inputFill,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    sharedPost.note,
                    style: TextStyle(
                      color: isMe
                          ? AppColors.surface
                          : AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),

              _SharedPostCard(payload: sharedPost),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.textPrimary : AppColors.inputFill,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isMe ? AppColors.surface : AppColors.textPrimary,
            fontSize: 15,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared Post Payload Parser
// ─────────────────────────────────────────────────────────────

class _SharedPostPayload {
  static const String marker = '__THREAD_SHARED_POST__';

  final String note;
  final int? postId;
  final String postLink;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String content;
  final List<String> mediaUrls;
  final String? location;

  const _SharedPostPayload({
    required this.note,
    required this.postId,
    required this.postLink,
    required this.authorUsername,
    required this.authorAvatarUrl,
    required this.content,
    required this.mediaUrls,
    required this.location,
  });

  static _SharedPostPayload? tryParse(String raw) {
    final text = raw.trim();

    if (text.startsWith(marker)) {
      try {
        final jsonText = text.substring(marker.length).trim();
        final map = jsonDecode(jsonText) as Map<String, dynamic>;

        final mediaList = map['media'];
        final List<String> urls = [];

        if (mediaList is List) {
          for (final item in mediaList) {
            if (item is Map) {
              final url = item['media_url'] ??
                  item['mediaUrl'] ??
                  item['url'] ??
                  item['image_url'];

              if (url != null && url.toString().trim().isNotEmpty) {
                urls.add(url.toString());
              }
            } else if (item != null) {
              final url = item.toString();
              if (url.trim().isNotEmpty) urls.add(url);
            }
          }
        }

        return _SharedPostPayload(
          note: (map['note'] ?? '').toString(),
          postId: _toInt(map['post_id'] ?? map['postId']),
          postLink: (map['post_link'] ?? map['postLink'] ?? '').toString(),
          authorUsername:
          (map['author_username'] ?? map['authorUsername'] ?? 'user')
              .toString(),
          authorAvatarUrl:
          (map['author_avatar_url'] ?? map['authorAvatarUrl'])
              ?.toString(),
          content: (map['content'] ?? '').toString(),
          mediaUrls: urls,
          location: map['location']?.toString(),
        );
      } catch (_) {
        return null;
      }
    }

    // Fallback cho tin nhắn share cũ dạng text:
    // "lời nhắn\n\nXem bài viết của @abc trên Thread City:\n\ncontent\n\nlink"
    if (text.contains('Xem bài viết của @') &&
        text.contains('trên Thread City:')) {
      final shareStart = text.indexOf('Xem bài viết của @');
      final note = shareStart > 0 ? text.substring(0, shareStart).trim() : '';

      final shareBody = text.substring(shareStart).trim();
      final usernameMatch =
      RegExp(r'Xem bài viết của @(.+?) trên Thread City:')
          .firstMatch(shareBody);

      final authorUsername = usernameMatch?.group(1)?.trim() ?? 'user';

      final parts = shareBody.split('\n\n');
      String content = '';
      String link = '';

      if (parts.length >= 2) {
        content = parts.sublist(1).join('\n\n').trim();

        final linkMatch =
        RegExp(r'https?:\/\/[^\s]+').firstMatch(content);

        if (linkMatch != null) {
          link = linkMatch.group(0) ?? '';
          content = content.replaceAll(link, '').trim();
        }
      }

      return _SharedPostPayload(
        note: note,
        postId: null,
        postLink: link,
        authorUsername: authorUsername,
        authorAvatarUrl: null,
        content: content,
        mediaUrls: const [],
        location: null,
      );
    }

    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

// ─────────────────────────────────────────────────────────────
// Shared Post Card
// ─────────────────────────────────────────────────────────────

class _SharedPostCard extends StatelessWidget {
  final _SharedPostPayload payload;

  const _SharedPostCard({
    required this.payload,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPostInApp(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.border,
            width: 0.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ChatAvatar(
                  username: payload.authorUsername,
                  avatarUrl: payload.authorAvatarUrl,
                  size: 34,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    payload.authorUsername,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.open_in_new_rounded,
                  color: AppColors.textSecondary,
                  size: 17,
                ),
              ],
            ),

            if (payload.content.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                payload.content,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ],

            if (payload.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SharedPostMediaGrid(mediaUrls: payload.mediaUrls),
            ],

            if (payload.location != null &&
                payload.location!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                payload.location!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 12),

            Row(
              children: const [
                Icon(
                  Icons.favorite_border_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                SizedBox(width: 18),
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.textSecondary,
                  size: 21,
                ),
                SizedBox(width: 18),
                Icon(
                  Icons.repeat_rounded,
                  color: AppColors.textSecondary,
                  size: 23,
                ),
                SizedBox(width: 18),
                Icon(
                  Icons.send_outlined,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _openPostInApp(BuildContext context) async {
    final postId = payload.postId;

    if (postId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy bài viết'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final authData = context.read<AuthProvider>().currentUserData;
      final viewerUid = authData?['firebase_uid'];

      final post = await context.read<PostProvider>().getPostById(
        postId,
        viewerUid: viewerUid,
      );

      if (post == null) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bài viết không còn tồn tại'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(post: post),
        ),
      );
    } catch (e) {
      debugPrint('[CHAT] Lỗi mở bài viết trong app: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở bài viết'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}



class _SharedPostMediaGrid extends StatelessWidget {
  final List<String> mediaUrls;

  const _SharedPostMediaGrid({
    required this.mediaUrls,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.network(
            mediaUrls.first,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      );
    }

    final shown = mediaUrls.take(2).toList();

    return SizedBox(
      height: 190,
      child: Row(
        children: [
          for (int i = 0; i < shown.length; i++) ...[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  shown[i],
                  height: 190,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            if (i != shown.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Avatar
// ─────────────────────────────────────────────────────────────

class _ChatAvatar extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final double size;

  const _ChatAvatar({
    required this.username,
    required this.avatarUrl,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackUrl =
        'https://api.dicebear.com/7.x/avataaars/png?seed=$username';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? Image.network(
          avatarUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.network(
            fallbackUrl,
            fit: BoxFit.cover,
          ),
        )
            : Image.network(
          fallbackUrl,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Typing Bubble
// ─────────────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final value =
              (_controller.value - index * 0.2).clamp(0.0, 1.0);
              final opacity = value < 0.5 ? 0.35 : 1.0;

              return AnimatedOpacity(
                opacity: opacity,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}