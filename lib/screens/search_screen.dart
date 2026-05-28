import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/search_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late FocusNode _searchFocus;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _trends = [
    {'tag': '#Flutter', 'count': 5420, 'category': 'Tech'},
    {'tag': '#ReactJS', 'count': 7870, 'category': 'Dev'},
    {'tag': '#TypeScript', 'count': 4267, 'category': 'Dev'},
    {'tag': '#WebDev', 'count': 9741, 'category': 'Design'},
    {'tag': '#AI', 'count': 6850, 'category': 'Tech'},
    {'tag': '#Design', 'count': 9259, 'category': 'Design'},
    {'tag': '#Python', 'count': 8930, 'category': 'Dev'},
  ];

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController();
    _searchFocus = FocusNode();

    _searchFocus.addListener(() {
      setState(() {});
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }

    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final hasQuery = searchProvider.hasQuery;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _searchFocus.hasFocus
                      ? AppColors.primaryAccent.withOpacity(0.4)
                      : AppColors.border,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm bài viết, người dùng...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: searchProvider.onQueryChanged,
                    ),
                  ),

                  if (hasQuery)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        context.read<SearchProvider>().clear();
                        setState(() {});
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          if (!hasQuery) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Xu hướng',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  fontSize: 20,
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _trends.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final trend = _trends[index];

                  return _TrendCard(
                    tag: trend['tag'] as String,
                    count: _formatCount(trend['count'] as int),
                    category: trend['category'] as String,
                    index: index,
                    onTap: () {
                      final tag = trend['tag'] as String;
                      _searchController.text = tag;
                      context.read<SearchProvider>().onQueryChanged(tag);
                    },
                  );
                },
              ),
            ),
          ] else ...[
            Expanded(
              child: _SearchResultView(
                provider: searchProvider,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchResultView extends StatelessWidget {
  final SearchProvider provider;

  const _SearchResultView({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textPrimary,
          ),
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text(
            provider.errorMessage!,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    if (!provider.hasResults) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border,
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 30,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Không tìm thấy kết quả',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thử tìm kiếm với từ khóa khác',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        if (provider.users.isNotEmpty) ...[
          const _SearchSectionTitle(title: 'Mọi người'),
          ...provider.users.map(
                (user) => _UserSearchCard(user: user),
          ),
          const SizedBox(height: 20),
        ],

        if (provider.hashtags.isNotEmpty) ...[
          const _SearchSectionTitle(title: 'Hashtag'),
          ...provider.hashtags.map(
                (tag) => _HashtagSearchCard(tag: tag),
          ),
          const SizedBox(height: 20),
        ],

        if (provider.posts.isNotEmpty) ...[
          const _SearchSectionTitle(title: 'Bài viết'),
          ...provider.posts.map(
                (post) => _PostSearchCard(post: post),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _SearchSectionTitle extends StatelessWidget {
  final String title;

  const _SearchSectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String tag;
  final String count;
  final String category;
  final int index;
  final VoidCallback onTap;

  const _TrendCard({
    required this.tag,
    required this.count,
    required this.category,
    required this.index,
    required this.onTap,
  });

  Color _categoryColor() {
    switch (category) {
      case 'Tech':
        return const Color(0xFF6C63FF);
      case 'Dev':
        return const Color(0xFF00C7A3);
      case 'Design':
        return const Color(0xFFFF6B6B);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.primaryAccent.withOpacity(0.05),
          highlightColor: AppColors.inputFill.withOpacity(0.6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tag,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$count bài viết',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _categoryColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _categoryColor(),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.icon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserSearchCard extends StatelessWidget {
  final dynamic user;

  const _UserSearchCard({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final username = user['username']?.toString() ?? '';
    final nickname = user['nickname']?.toString();
    final bio = user['bio']?.toString();
    final avatarUrl = user['avatar_url']?.toString();
    final isVerified = user['is_verified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.inputFill,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            )
                : null,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        nickname != null && nickname.isNotEmpty
                            ? nickname
                            : username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: AppColors.primaryAccent,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 2),

                Text(
                  '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                if (bio != null && bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    bio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Theo dõi',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HashtagSearchCard extends StatelessWidget {
  final dynamic tag;

  const _HashtagSearchCard({
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final tagName = tag['tag_name']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.inputFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tag_rounded,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              '#$tagName',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.icon,
          ),
        ],
      ),
    );
  }
}

class _PostSearchCard extends StatelessWidget {
  final dynamic post;

  const _PostSearchCard({
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final content = post['content']?.toString() ?? '';
    final user = post['user'];

    final username = user?['username']?.toString() ?? 'user';
    final nickname = user?['nickname']?.toString();
    final avatarUrl = user?['avatar_url']?.toString();
    final isVerified = user?['is_verified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.inputFill,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            )
                : null,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        nickname != null && nickname.isNotEmpty
                            ? nickname
                            : username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: AppColors.primaryAccent,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 2),

                Text(
                  '@$username',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}