import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const trends = [
      '#ReactJS',
      '#TypeScript',
      '#WebDev',
      '#Design',
      '#AI',
    ];

    const counts = [7870, 267, 9741, 9259, 6850];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.icon),
              filled: true,
              fillColor: const Color(0xFFF1F1F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Xu hướng hiện tại',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: trends.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: index == 1 ? const Color(0xFFF7F7FA) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trends[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${counts[index]} bài viết',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                     ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}