import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'repositories/auth_repository.dart';
import 'repositories/post_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/search_repository.dart';

import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'providers/user_provider.dart';
import 'providers/post_provider.dart';
import 'providers/search_provider.dart';

import 'routes/app_routes.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'repositories/notification_repository.dart';
import 'providers/activity_provider.dart';
import 'repositories/message_repository.dart';
import 'providers/message_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('✅ [FIREBASE] Core ready');

  final authRepository = AuthRepository(AppConfig.authUrl);
  final postRepository = PostRepository();
  final userRepository = UserRepository();
  final searchRepository = SearchRepository();
  final notificationRepository = NotificationRepository();
  final messageRepository = MessageRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<IPostRepository>.value(value: postRepository),
        Provider<IUserRepository>.value(value: userRepository),
        Provider<SearchRepository>.value(value: searchRepository),
        Provider<NotificationRepository>.value(value: notificationRepository),
        Provider<MessageRepository>.value(value: messageRepository),

        ChangeNotifierProvider(
          create: (_) => MessageProvider(messageRepository),
        ),

        ChangeNotifierProvider(
          create: (_) => ActivityProvider(notificationRepository),
        ),

        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository),
        ),

        ChangeNotifierProxyProvider<AuthProvider, HomeProvider>(
          create: (context) =>
              HomeProvider(postRepository, context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              HomeProvider(postRepository, auth),
        ),

        ChangeNotifierProxyProvider<AuthProvider, PostProvider>(
          create: (context) =>
              PostProvider(postRepository, context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              PostProvider(postRepository, auth),
        ),

        ChangeNotifierProvider(
          create: (_) => UserProvider(userRepository, postRepository),
        ),

        ChangeNotifierProvider(
          create: (_) => SearchProvider(searchRepository),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Threads Clone',
          theme: AppTheme.lightTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: auth.isAuthenticated ? MainScreen() : LoginScreen(),
        );
      },
    );
  }
}