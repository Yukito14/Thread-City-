import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../widgets/post_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: mockPosts.length,
      itemBuilder: (context, index) {
        return PostCard(post: mockPosts[index]);
      },
    );
  }
}