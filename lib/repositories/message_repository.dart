import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../config/app_config.dart';

class MessageRepository {
  final String baseUrl = AppConfig.baseUrl;

  IO.Socket? _socket;

  bool get isSocketConnected => _socket?.connected ?? false;

  // ================= REST API =================

  Future<List<Map<String, dynamic>>> getConversations(String firebaseUid) async {
    final uri = Uri.parse('$baseUrl/messages/conversations').replace(
      queryParameters: {
        'firebase_uid': firebaseUid,
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    throw Exception('Không thể tìm kiếm người dùng');
  }

  Future<Map<String, dynamic>> createOrGetConversation({
    required String firebaseUid,
    required int targetUserId,
  }) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/messages/conversations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebase_uid': firebaseUid,
        'target_user_id': targetUserId,
      }),
    )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map,
      );
    }

    throw Exception('Không thể tạo cuộc trò chuyện');
  }

  Future<List<Map<String, dynamic>>> getMessages({
    required int conversationId,
    required String firebaseUid,
  }) async {
    final uri =
    Uri.parse('$baseUrl/messages/conversations/$conversationId/messages')
        .replace(
      queryParameters: {
        'firebase_uid': firebaseUid,
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    throw Exception('Không thể tải tin nhắn');
  }

  Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required String firebaseUid,
    required String content,
  }) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/messages/conversations/$conversationId/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebase_uid': firebaseUid,
        'content': content,
      }),
    )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map,
      );
    }

    throw Exception('Không thể gửi tin nhắn');
  }

  Future<void> markAsRead({
    required int conversationId,
    required String firebaseUid,
  }) async {
    await http
        .patch(
      Uri.parse('$baseUrl/messages/conversations/$conversationId/read'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebase_uid': firebaseUid,
      }),
    )
        .timeout(const Duration(seconds: 10));
  }

  // ================= SOCKET.IO =================

  void connectSocket({
    required String firebaseUid,
    required void Function(dynamic data) onReceiveMessage,
    required void Function(dynamic data) onNewMessageNotification,
    required void Function(dynamic data) onSocketError,
  }) {
    if (_socket == null) {
      _socket = IO.io(
        AppConfig.socketUrl,
        <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
          'reconnection': true,
          'reconnectionAttempts': 999,
          'reconnectionDelay': 1000,
        },
      );
    }

    // Tránh bị đăng ký listener trùng nhiều lần
    _socket!.off('receive_message');
    _socket!.off('new_message_notification');
    _socket!.off('socket_error');
    _socket!.off('connect');
    _socket!.off('connect_error');
    _socket!.off('disconnect');

    _socket!.on('connect', (_) {
      print('[SOCKET] ✅ Connected: ${_socket!.id}');
      _socket!.emit('join_user', {
        'firebase_uid': firebaseUid,
      });
    });

    _socket!.on('receive_message', (data) {
      print('[SOCKET] 📩 receive_message: $data');
      onReceiveMessage(data);
    });

    _socket!.on('new_message_notification', (data) {
      print('[SOCKET] 🔔 new_message_notification: $data');
      onNewMessageNotification(data);
    });

    _socket!.on('socket_error', (data) {
      print('[SOCKET] ❌ socket_error: $data');
      onSocketError(data);
    });

    _socket!.on('connect_error', (data) {
      print('[SOCKET] ❌ connect_error: $data');
      onSocketError(data);
    });

    _socket!.on('disconnect', (_) {
      print('[SOCKET] 🔌 Disconnected');
    });

    if (!_socket!.connected) {
      _socket!.connect();
    } else {
      _socket!.emit('join_user', {
        'firebase_uid': firebaseUid,
      });
    }
  }

  void joinConversation(int conversationId) {
    if (_socket == null) return;

    _socket!.emit('join_conversation', {
      'conversation_id': conversationId,
    });

    print('[SOCKET] 🚪 join_conversation: $conversationId');
  }

  void leaveConversation(int conversationId) {
    if (_socket == null) return;

    _socket!.emit('leave_conversation', {
      'conversation_id': conversationId,
    });

    print('[SOCKET] 🚪 leave_conversation: $conversationId');
  }

  void emitTyping({
    required int conversationId,
    required String firebaseUid,
  }) {
    _socket?.emit('typing', {
      'conversation_id': conversationId,
      'firebase_uid': firebaseUid,
    });
  }

  void emitStopTyping({
    required int conversationId,
    required String firebaseUid,
  }) {
    _socket?.emit('stop_typing', {
      'conversation_id': conversationId,
      'firebase_uid': firebaseUid,
    });
  }

  void disposeSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}