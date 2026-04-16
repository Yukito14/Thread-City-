import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import 'activity_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'write_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.currentUsername,
    required this.currentNickname,
  });

  final String currentUsername;
  final String currentNickname;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const SearchScreen(),
      WriteScreen(currentUsername: widget.currentUsername),
      const ActivityScreen(),
      ProfileScreen(
        currentUsername: widget.currentUsername,
        currentNickname: widget.currentNickname,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: const AppLogo(size: 42),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (value) {
          setState(() => currentIndex = value);
        },
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: ''),
          NavigationDestination(icon: Icon(Icons.search), label: ''),
          NavigationDestination(icon: Icon(Icons.edit_square), label: ''),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: ''),
          NavigationDestination(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
    );
  }
}