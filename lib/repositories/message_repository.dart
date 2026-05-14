import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class MessageRepository {
  final String baseUrl = AppConfig.baseUrl;

  Future<List<Map<String, dynamic>>> getConversations(String firebaseUid) async {
    final uri = Uri.parse('$baseUrl/messages/conversations').replace(
      queryParameters: {
        'firebase_uid': firebaseUid,
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => e as Map<String, dynamic>).toList();
    }

    throw Exception('Không thể tải danh sách tin nhắn');
  }

  Future<List<Map<String, dynamic>>> searchUsers({
    required String keyword,
    required String firebaseUid,
  }) async {
    final uri = Uri.parse('$baseUrl/messages/users/search').replace(
      queryParameters: {
        'q': keyword,
        'firebase_uid': firebaseUid,
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => e as Map<String, dynamic>).toList();
    }

    throw Exception('Không thể tìm kiếm người dùng');
  }

  Future<Map<String, dynamic>> createOrGetConversation({
    required String firebaseUid,
    required int targetUserId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/conversations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebase_uid': firebaseUid,
        'target_user_id': targetUserId,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }

    throw Exception('Không thể tạo cuộc trò chuyện');
  }

  Future<List<Map<String, dynamic>>> getMessages({
    required int conversationId,
    required String firebaseUid,
  }) async {
    final uri = Uri.parse('$baseUrl/messages/conversations/$conversationId/messages')
        .replace(
      queryParameters: {
        'firebase_uid': firebaseUid,
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => e as Map<String, dynamic>).toList();
    }

    throw Exception('Không thể tải tin nhắn');
  }

  Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required String firebaseUid,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/conversations/$conversationId/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebase_uid': firebaseUid,
        'content': content,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }

    throw Exception('Không thể gửi tin nhắn');
  }

  Future<void> markAsRead({
    required int conversationId,
    required String firebaseUid,
  }) async {
    await http.patch(
      Uri.parse('$baseUrl/messages/conversations/$conversationId/read'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebase_uid': firebaseUid,
      }),
    ).timeout(const Duration(seconds: 10));
  }
}