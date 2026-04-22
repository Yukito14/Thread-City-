import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/main_screen.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool showSignIn = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isAuthenticated) {
      return MainScreen(
        currentUsername: auth.currentUser!.username,
        currentNickname: auth.currentUser!.nickname,
      );
    }

    if (showSignIn) {
      return SignInScreen(
        onSwitchToSignUp: () => setState(() => showSignIn = false),
      );
    }

    return SignUpScreen(
      onSignUp: (username, nickname) {
        // Tạm thời giữ hàm cũ cho SignUp nếu bạn chỉ muốn focus Đăng nhập trước
        // (Nếu muốn có thể đổi sang dùng auth.signUp(..))
      },
      onSwitchToSignIn: () => setState(() => showSignIn = true),
    );
  }
}