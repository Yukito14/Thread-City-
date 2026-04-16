import 'package:flutter/material.dart';
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
  String currentUsername = 'anhthu031020051';
  String currentNickname = 'anhthu031020051@gmail.com';

  void handleLogin(String username) {
    setState(() {
      currentUsername = username.isEmpty ? 'user' : username;
      currentNickname = username.isEmpty ? 'user' : username;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreen(
          currentUsername: currentUsername,
          currentNickname: currentNickname,
        ),
      ),
    );
  }

  void handleSignUp(String username, String nickname) {
    setState(() {
      currentUsername = username.isEmpty ? 'user' : username;
      currentNickname = nickname.isEmpty ? currentUsername : nickname;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreen(
          currentUsername: currentUsername,
          currentNickname: currentNickname,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showSignIn) {
      return SignInScreen(
        onLogin: handleLogin,
        onSwitchToSignUp: () => setState(() => showSignIn = false),
      );
    }

    return SignUpScreen(
      onSignUp: handleSignUp,
      onSwitchToSignIn: () => setState(() => showSignIn = true),
    );
  }
}