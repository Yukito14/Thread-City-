import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
    required this.onSignUp,
    required this.onSwitchToSignIn,
  });

  final void Function(String username, String nickname) onSignUp;
  final VoidCallback onSwitchToSignIn;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final usernameController = TextEditingController();
  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const AppLogo(size: 82),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 430),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Tạo tài khoản',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _FieldLabel('Tên người dùng'),
                      AppTextField(
                        controller: usernameController,
                        hintText: 'username',
                      ),
                      const SizedBox(height: 18),
                      const _FieldLabel('Biệt danh'),
                      AppTextField(
                        controller: nicknameController,
                        hintText: 'Tên hiển thị của bạn',
                      ),
                      const SizedBox(height: 18),
                      const _FieldLabel('Email'),
                      AppTextField(
                        controller: emailController,
                        hintText: 'email@example.com',
                      ),
                      const SizedBox(height: 18),
                      const _FieldLabel('Mật khẩu'),
                      AppTextField(
                        controller: passwordController,
                        hintText: '••••••••',
                        obscureText: true,
                      ),
                      const SizedBox(height: 18),
                      const _FieldLabel('Xác nhận mật khẩu'),
                      AppTextField(
                        controller: confirmPasswordController,
                        hintText: '••••••••',
                        obscureText: true,
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (passwordController.text !=
                                confirmPasswordController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mật khẩu không khớp'),
                                ),
                              );
                              return;
                            }

                            widget.onSignUp(
                              usernameController.text.trim(),
                              nicknameController.text.trim(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Tạo tài khoản',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: GestureDetector(
                          onTap: widget.onSwitchToSignIn,
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                TextSpan(text: 'Đã có tài khoản? '),
                                TextSpan(
                                  text: 'Đăng nhập',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}