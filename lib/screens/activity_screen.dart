import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification_model.dart';
import '../providers/activity_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String? _initializedUid;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFirstTime();
    });
  }

  void _loadFirstTime() {
    final auth = context.read<AuthProvider>();
    final firebaseUid = auth.currentUserData?['firebase_uid']?.toString() ?? '';

    if (firebaseUid.isEmpty) return;

    _initializedUid = firebaseUid;

    context.read<ActivityProvider>().fetchNotifications(firebaseUid);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite_rounded;
      case 'reply':
        return Icons.chat_bubble_rounded;
      case 'follow':
        return Icons.person_add_rounded;
      case 'repost':
        return Icons.repeat_rounded;
      case 'mention':
        return Icons.alternate_email_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'like':
        return const Color(0xFFFF6B6B);
      case 'reply':
        return const Color(0xFF339AF0);
      case 'follow':
        return const Color(0xFF51CF66);
      case 'repost':
        return const Color(0xFFA78BFA);
      case 'mention':
        return const Color(0xFFFFA94D);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ActivityProvider>();

    final firebaseUid = auth.currentUserData?['firebase_uid']?.toString() ?? '';

    if (_initializedUid != firebaseUid && firebaseUid.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _initializedUid = firebaseUid;
        context.read<ActivityProvider>().fetchNotifications(firebaseUid);
      });
    }

    return FadeTransition(
      opacity: _animController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: provider.filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = provider.selectedFilter == index;

                return GestureDetector(
                  onTap: firebaseUid.isEmpty
                      ? null
                      : () {
                    context.read<ActivityProvider>().changeFilter(
                      index: index,
                      firebaseUid: firebaseUid,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      provider.filters[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.surface
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: _buildBody(
              context: context,
              provider: provider,
              firebaseUid: firebaseUid,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required ActivityProvider provider,
    required String firebaseUid,
  }) {
    if (firebaseUid.isEmpty) {
      return const _ActivityEmptyState(
        icon: Icons.person_outline_rounded,
        title: 'Chưa đăng nhập',
        subtitle: 'Bạn cần đăng nhập để xem thông báo',
      );
    }

    if (provider.isLoading && !provider.hasLoaded) {
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

    if (provider.errorMessage != null && provider.notifications.isEmpty) {
      return _ActivityEmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Không tải được thông báo',
        subtitle: provider.errorMessage!,
      );
    }

    if (provider.notifications.isEmpty) {
      return const _ActivityEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'Chưa có hoạt động nào',
        subtitle: 'Khi có lượt thích, bình luận hoặc theo dõi, thông báo sẽ hiện ở đây',
      );
    }

    return RefreshIndicator(
      color: AppColors.textPrimary,
      backgroundColor: AppColors.surface,
      onRefresh: () => provider.refresh(firebaseUid),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: provider.notifications.length,
        itemBuilder: (context, index) {
          final item = provider.notifications[index];

          return _ActivityTile(
            item: item,
            typeIcon: _typeIcon(item.type),
            typeColor: _typeColor(item.type),
          );
        },
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final AppNotification item;
  final IconData typeIcon;
  final Color typeColor;

  const _ActivityTile({
    required this.item,
    required this.typeIcon,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isNew = !item.isRead;
    final preview = item.previewText;
    final actor = item.actor;

    return Container(
      color: isNew
          ? AppColors.textPrimary.withOpacity(0.02)
          : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.border,
                      width: 0.8,
                    ),
                  ),
                  child: ClipOval(
                    child: actor.avatarUrl != null &&
                        actor.avatarUrl!.isNotEmpty
                        ? Image.network(
                      actor.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return _AvatarFallback(text: actor.initials);
                      },
                    )
                        : _AvatarFallback(text: actor.initials),
                  ),
                ),

                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: typeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      typeIcon,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: actor.displayName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (actor.isVerified)
                                const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.verified_rounded,
                                      size: 14,
                                      color: AppColors.primaryAccent,
                                    ),
                                  ),
                                ),
                              TextSpan(
                                text: ' ${item.actionText}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Row(
                        children: [
                          if (isNew)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(
                                right: 6,
                                top: 6,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryAccent,
                                shape: BoxShape.circle,
                              ),
                            ),

                          Text(
                            item.timeAgo,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        preview,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String text;

  const _AvatarFallback({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ActivityEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ActivityEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 42),
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
              child: Icon(
                icon,
                size: 30,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}