import 'package:flutter/material.dart';

import '../screens/main_screen.dart';
import '../screens/register_screen.dart';
import '../screens/login_screen.dart';
import '../screens/nickname_setup_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String register = '/register';
  static const String login = '/login';
  static const String nicknameSetup = '/nickname-setup';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case nicknameSetup:
        return MaterialPageRoute(
          builder: (_) => const NicknameSetupScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}