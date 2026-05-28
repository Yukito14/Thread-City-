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
import 'screens/nickname_setup_screen.dart';

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
import 'package:firebase_messaging/firebase_messaging.dart';

import 'services/push_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('[FCM] 📩 Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
          home: auth.isAuthenticated
              ? const _AuthenticatedEntry()
              : LoginScreen(),
        );
      },
    );
  }
}

class _AuthenticatedEntry extends StatefulWidget {
  const _AuthenticatedEntry();

  @override
  State<_AuthenticatedEntry> createState() => _AuthenticatedEntryState();
}

class _AuthenticatedEntryState extends State<_AuthenticatedEntry> {
  String? _initializedUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.watch<AuthProvider>();
    final uid = auth.currentUserData?['firebase_uid'];

    if (uid == null || uid == _initializedUid) return;

    _initializedUid = uid;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final messageRepository = context.read<MessageRepository>();

      try {
        await PushNotificationService(messageRepository).init(
          firebaseUid: uid,
        );
      } catch (e) {
        print('[FCM] ❌ Init error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.hasNickname) {
      return const NicknameSetupScreen();
    }

    return const MainScreen();
  }
}