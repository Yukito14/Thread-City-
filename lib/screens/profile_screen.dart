import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/post_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.currentUsername,
    required this.currentNickname,
  });

  final String currentUsername;
  final String currentNickname;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundImage: NetworkImage(
                      'https://api.dicebear.com/7.x/avataaars/png?seed=$currentUsername',
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text(
                      'Đăng xuất',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                currentNickname,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '@$currentUsername',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Text(
                    '156 ',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  Text(
                    'Đang theo dõi',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 22),
                  Text(
                    '1.2K ',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  Text(
                    'Người theo dõi',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Bài viết của bạn',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: mockPosts.length,
            itemBuilder: (context, index) {
              final post = mockPosts[index];
              return PostCard(
                post: post,
              );
            },
          ),
        ),
      ],
    );
  }
}