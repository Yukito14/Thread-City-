import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../theme/app_colors.dart';
import 'dart:async';

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
              child: Text(
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
            ),
          ],
        ),
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
                          message['content'] ?? '',
                          style: TextStyle(
                            color: isMe ? AppColors.surface : AppColors.textPrimary,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ),
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

class _ChatAvatar extends StatelessWidget {
  final String username;
  final String? avatarUrl;

  const _ChatAvatar({
    required this.username,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackUrl = 'https://api.dicebear.com/7.x/avataaars/png?seed=$username';

    return Container(
      width: 34,
      height: 34,
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
              final value = (_controller.value - index * 0.2).clamp(0.0, 1.0);
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