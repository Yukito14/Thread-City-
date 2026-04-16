import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post});

  final PostModel post;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool isLiked;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    isLiked = false;
    likeCount = widget.post.likes;
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(post.authorAvatar),
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
                        post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (post.verified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 18, color: Colors.blue),
                    ],
                    const Spacer(),
                    const Icon(Icons.more_horiz, color: AppColors.icon),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${post.authorUsername}  ·  ${post.timeAgo}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  post.content,
                  style: const TextStyle(fontSize: 16, height: 1.45),
                ),
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      post.imageUrl!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    _ActionButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : AppColors.icon,
                      text: FormatUtils.formatCount(likeCount),
                      onTap: toggleLike,
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.mode_comment_outlined,
                      text: FormatUtils.formatCount(post.replies),
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.repeat,
                      text: FormatUtils.formatCount(post.reposts),
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.send_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    this.text,
    this.onTap,
    this.color = AppColors.icon,
  });

  final IconData icon;
  final String? text;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          if (text != null) ...[
            const SizedBox(width: 6),
            Text(
              text!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ]
        ],
      ),
    );
  }
}