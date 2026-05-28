import 'package:flutter/material.dart';

import '../repositories/notification_repository.dart';
import '../models/notification_model.dart';

class ActivityProvider extends ChangeNotifier {
  final NotificationRepository notificationRepository;

  ActivityProvider(this.notificationRepository);

  int selectedFilter = 0;
  bool isLoading = false;
  bool hasLoaded = false;
  String? errorMessage;

  List<AppNotification> notifications = [];

  final filters = const [
    'Tất cả',
    'Lượt thích',
    'Bình luận',
    'Theo dõi',
  ];

  String? get selectedType {
    switch (selectedFilter) {
      case 1:
        return 'like';
      case 2:
        return 'reply';
      case 3:
        return 'follow';
      default:
        return null;
    }
  }

  Future<void> fetchNotifications(String firebaseUid) async {
    if (firebaseUid.isEmpty) return;

    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      notifications = await notificationRepository.getNotifications(
        firebaseUid: firebaseUid,
        type: selectedType,
      );

      hasLoaded = true;
    } catch (e) {
      errorMessage = 'Không thể tải thông báo. Vui lòng thử lại.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh(String firebaseUid) async {
    await fetchNotifications(firebaseUid);
  }

  Future<void> changeFilter({
    required int index,
    required String firebaseUid,
  }) async {
    selectedFilter = index;
    notifyListeners();

    await fetchNotifications(firebaseUid);
  }

  Future<void> markAllAsRead(String firebaseUid) async {
    try {
      await notificationRepository.markAllAsRead(
        firebaseUid: firebaseUid,
      );

      notifications = notifications
          .map(
            (item) => AppNotification(
          id: item.id,
          type: item.type,
          isRead: true,
          createdAt: item.createdAt,
          actor: item.actor,
          post: item.post,
        ),
      )
          .toList();

      notifyListeners();
    } catch (_) {}
  }
}