import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      {
        'icon': Icons.favorite,
        'color': Colors.red,
        'user': 'Sarah Chen',
        'content': 'đã thích bài viết của bạn',
        'time': '2h',
      },
      {
        'icon': Icons.mode_comment_outlined,
        'color': Colors.blue,
        'user': 'Alex Kim',
        'content': 'đã trả lời bài viết của bạn',
        'time': '4h',
      },
      {
        'icon': Icons.person_outline,
        'color': Colors.green,
        'user': 'Maria Garcia',
        'content': 'đã theo dõi bạn',
        'time': '1d',
      },
      {
        'icon': Icons.favorite,
        'color': Colors.red,
        'user': 'David Park',
        'content': 'đã thích bình luận của bạn',
        'time': '1d',
      },
      {
        'icon': Icons.repeat,
        'color': Colors.purple,
        'user': 'Emma Wilson',
        'content': 'đã chia sẻ bài viết của bạn',
        'time': '2d',
      },
    ];

    return ListView.separated(
      itemCount: activities.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final item = activities[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item['icon'] as IconData,
                color: item['color'] as Color,
                size: 34,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                        children: [
                          TextSpan(
                            text: '${item['user']} ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: item['content'] as String,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['time'] as String,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}