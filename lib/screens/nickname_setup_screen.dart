import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class NicknameSetupScreen extends StatefulWidget {
  const NicknameSetupScreen({super.key});

  @override
  State<NicknameSetupScreen> createState() => _NicknameSetupScreenState();
}

class _NicknameSetupScreenState extends State<NicknameSetupScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveNickname() async {
    final nickname = _nicknameController.text.trim();

    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập biệt danh'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (nickname.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biệt danh phải có ít nhất 2 ký tự'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.updateNickname(nickname);

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Cập nhật biệt danh thất bại',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1,
                    color: Colors.white,
                    size: 48,
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Đặt biệt danh của bạn',
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Biệt danh sẽ hiển thị với mọi người trong Threads',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                TextField(
                  controller: _nicknameController,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleSaveNickname(),
                  decoration: InputDecoration(
                    labelText: 'Biệt danh',
                    hintText: 'Ví dụ: Bright',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    prefixIconColor: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSaveNickname,
                    child: isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                        : const Text(
                      'Tiếp tục',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}