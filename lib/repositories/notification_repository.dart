import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../../models/notification_model.dart';

class NotificationRepository {
  final String baseUrl = AppConfig.baseUrl;

  Future<List<AppNotification>> getNotifications({
    required String firebaseUid,
    String? type,
  }) async {
    final params = <String, String>{
      'firebase_uid': firebaseUid,
    };

    if (type != null && type.isNotEmpty && type != 'all') {
      params['type'] = type;
    }

    final uri = Uri.parse('$baseUrl/notifications').replace(
      queryParameters: params,
    );

    final response = await http.get(uri).timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((item) => AppNotification.fromMap(
        Map<String, dynamic>.from(item),
      ))
          .toList();
    }

    throw Exception('Không thể tải thông báo. Lỗi: ${response.statusCode}');
  }

  Future<void> markAllAsRead({
    required String firebaseUid,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'firebase_uid': firebaseUid,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể đánh dấu đã đọc');
    }
  }

  Future<void> markAsRead({
    required int notificationId,
    required String firebaseUid,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'firebase_uid': firebaseUid,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể cập nhật thông báo');
    }
  }
}