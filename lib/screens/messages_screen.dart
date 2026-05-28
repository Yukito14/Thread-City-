import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../theme/app_colors.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _keyword = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUserData?['firebase_uid'];
      if (uid != null) {
        final messageProvider = context.read<MessageProvider>();

        messageProvider.connectSocket(uid);
        messageProvider.loadConversations(uid);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _keyword = value.trim();
    });

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () {
      final uid = context.read<AuthProvider>().currentUserData?['firebase_uid'];
      if (uid == null) return;

      if (_keyword.isEmpty) {
        context.read<MessageProvider>().clearSearch();
      } else {
        context.read<MessageProvider>().searchUsers(
          keyword: _keyword,
          firebaseUid: uid,
        );
      }
    });
  }

  Future<void> _openChatFromUser(Map<String, dynamic> user) async {
    final uid = context.read<AuthProvider>().currentUserData?['firebase_uid'];
    final targetId = user['id'];

    if (uid == null || targetId == null) return;

    final conversation = await context.read<MessageProvider>().createOrGetConversation(
      firebaseUid: uid,
      targetUserId: targetId is int ? targetId : int.parse(targetId.toString()),
    );

    if (!mounted || conversation == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversation['id'],
          otherUser: conversation['other_user'] ?? user,
        ),
      ),
    );
  }

  void _openChatFromConversation(Map<String, dynamic> conversation) {
    final otherUser = conversation['other_user'] ?? {};

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversation['id'],
          otherUser: otherUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Text(
          'Tin nhắn',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit_square,
              color: AppColors.textPrimary,
              size: 24,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<MessageProvider>(
        builder: (context, provider, child) {
          final isSearchingMode = _keyword.isNotEmpty;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm người dùng',
                    hintStyle: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textTertiary,
                      size: 22,
                    ),
                    suffixIcon: _keyword.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
                    filled: true,
                    fillColor: AppColors.inputFill,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: isSearchingMode
                    ? _buildSearchResult(provider)
                    : _buildConversationList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchResult(MessageProvider provider) {
    if (provider.isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.textPrimary,
          strokeWidth: 2,
        ),
      );
    }

    if (provider.searchResults.isEmpty) {
      return const _EmptyMessageState(
        icon: Icons.person_search_rounded,
        title: 'Không tìm thấy người dùng',
        subtitle: 'Thử nhập tên người dùng khác.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final user = provider.searchResults[index];

        return _UserMessageTile(
          user: user,
          subtitle: user['bio'] ?? 'Nhấn để bắt đầu trò chuyện',
          onTap: () => _openChatFromUser(user),
        );
      },
    );
  }

  Widget _buildConversationList(MessageProvider provider) {
    if (provider.isLoadingConversations && provider.conversations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.textPrimary,
          strokeWidth: 2,
        ),
      );
    }

    if (provider.conversations.isEmpty) {
      return const _EmptyMessageState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Chưa có tin nhắn',
        subtitle: 'Tìm kiếm người dùng để bắt đầu trò chuyện.',
      );
    }

    return RefreshIndicator(
      color: AppColors.textPrimary,
      onRefresh: () async {
        final uid = context.read<AuthProvider>().currentUserData?['firebase_uid'];
        if (uid != null) {
          await context.read<MessageProvider>().loadConversations(uid);
        }
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4),
        itemCount: provider.conversations.length,
        itemBuilder: (context, index) {
          final conversation = provider.conversations[index];
          final otherUser = conversation['other_user'] ?? {};
          final lastMessage = conversation['last_message'];
          final unreadCount = conversation['unread_count'] ?? 0;

          return _UserMessageTile(
            user: otherUser,
            subtitle: lastMessage?['content'] ?? 'Bắt đầu trò chuyện',
            trailing: unreadCount > 0
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: AppColors.surface,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
                : null,
            onTap: () => _openChatFromConversation(conversation),
          );
        },
      ),
    );
  }
}

class _UserMessageTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _UserMessageTile({
    required this.user,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final username = user['username'] ?? 'user';
    final nickname = user['nickname'] ?? username;
    final avatarUrl = user['avatar_url'];

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: _Avatar(
        username: username,
        avatarUrl: avatarUrl,
        size: 56,
      ),
      title: Text(
        username,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      subtitle: Text(
        subtitle.isNotEmpty ? subtitle : nickname,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      trailing: trailing,
    );
  }
}

class _Avatar extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final double size;

  const _Avatar({
    required this.username,
    required this.avatarUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackUrl = 'https://api.dicebear.com/7.x/avataaars/png?seed=$username';

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

class _EmptyMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyMessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: AppColors.textTertiary),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}