import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key, required this.currentUsername});

  final String currentUsername;

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPost = controller.text.trim().isNotEmpty;

    return StatefulBuilder(
      builder: (context, setInnerState) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(
                        'https://api.dicebear.com/7.x/avataaars/png?seed=${widget.currentUsername}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          hintText: 'Bạn đang nghĩ gì?',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setInnerState(() {}),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Divider(color: AppColors.border),
                Row(
                  children: [
                    const Icon(Icons.image_outlined, color: AppColors.icon),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: canPost ? () {} : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        canPost ? Colors.black : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        'Đăng',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}