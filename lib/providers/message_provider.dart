import 'package:flutter/material.dart';
import '../repositories/message_repository.dart';

class MessageProvider extends ChangeNotifier {
  final MessageRepository _repository;

  MessageProvider(this._repository);

  List<Map<String, dynamic>> conversations = [];
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> messages = [];

  int get totalUnreadCount {
    int total = 0;

    for (final conversation in conversations) {
      total += _toInt(conversation['unread_count']) ?? 0;
    }

    return total;
  }

  bool isLoadingConversations = false;
  bool isSearching = false;
  bool isLoadingMessages = false;
  bool isSending = false;
  bool isSocketConnected = false;
  bool isOtherUserTyping = false;

  String? errorMessage;

  String? _currentFirebaseUid;
  int? _activeConversationId;
  final Set<int> _messageIds = {};

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  void connectSocket(String firebaseUid) {
    _currentFirebaseUid = firebaseUid;

    _repository.connectSocket(
      firebaseUid: firebaseUid,
      onReceiveMessage: _handleReceiveMessage,
      onNewMessageNotification: _handleNewMessageNotification,
      onTyping: _handleTyping,
      onStopTyping: _handleStopTyping,
      onSocketError: (data) {
        errorMessage = data.toString();
        notifyListeners();
      },
    );

    isSocketConnected = true;
    notifyListeners();
  }

  void _handleReceiveMessage(dynamic data) {
    final message = _toMap(data);
    final conversationId = _toInt(message['conversation_id']);

    if (conversationId == null) return;

    final uid = _currentFirebaseUid;

    if (_activeConversationId == conversationId) {
      _addMessageIfNew(message);

      if (uid != null) {
        _repository
            .markAsRead(
          conversationId: conversationId,
          firebaseUid: uid,
        )
            .then((_) {
          _setConversationUnreadCount(conversationId, 0);
          notifyListeners();
          loadConversations(uid);
        });
      }

      return;
    }

    if (uid != null) {
      loadConversations(uid);
    }
  }

  void _handleNewMessageNotification(dynamic data) {
    final uid = _currentFirebaseUid;
    if (uid != null) {
      loadConversations(uid);
    }
  }

  void _handleTyping(dynamic data) {
    final typingData = _toMap(data);

    final conversationId = _toInt(typingData['conversation_id']);
    final typingUid = typingData['firebase_uid'];

    if (conversationId == null) return;

    final isCurrentConversation = _activeConversationId == conversationId;
    final isOtherUser = typingUid != _currentFirebaseUid;

    if (isCurrentConversation && isOtherUser) {
      isOtherUserTyping = true;
      notifyListeners();
    }
  }

  void _handleStopTyping(dynamic data) {
    final typingData = _toMap(data);

    final conversationId = _toInt(typingData['conversation_id']);
    final typingUid = typingData['firebase_uid'];

    if (conversationId == null) return;

    final isCurrentConversation = _activeConversationId == conversationId;
    final isOtherUser = typingUid != _currentFirebaseUid;

    if (isCurrentConversation && isOtherUser) {
      isOtherUserTyping = false;
      notifyListeners();
    }
  }

  bool _addMessageIfNew(Map<String, dynamic> message) {
    final id = _toInt(message['id']);

    if (id != null && _messageIds.contains(id)) {
      return false;
    }

    if (id != null) {
      _messageIds.add(id);
    }

    messages.add(message);
    notifyListeners();
    return true;
  }

  void _setConversationUnreadCount(int conversationId, int count) {
    conversations = conversations.map((conversation) {
      final id = _toInt(conversation['id']);

      if (id == conversationId) {
        final updated = Map<String, dynamic>.from(conversation);
        updated['unread_count'] = count;
        return updated;
      }

      return conversation;
    }).toList();
  }

  void joinConversation(int conversationId) {
    _activeConversationId = conversationId;
    isOtherUserTyping = false;
    _repository.joinConversation(conversationId);
    notifyListeners();
  }

  void leaveConversation(int conversationId) {
    if (_activeConversationId == conversationId) {
      _activeConversationId = null;
      isOtherUserTyping = false;
    }

    _repository.leaveConversation(conversationId);
    notifyListeners();
  }

  Future<void> loadConversations(String firebaseUid) async {
    isLoadingConversations = true;
    errorMessage = null;
    notifyListeners();

    try {
      conversations = await _repository.getConversations(firebaseUid);
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoadingConversations = false;
    notifyListeners();
  }

  Future<void> searchUsers({
    required String keyword,
    required String firebaseUid,
  }) async {
    if (keyword.trim().isEmpty) {
      searchResults = [];
      notifyListeners();
      return;
    }

    isSearching = true;
    errorMessage = null;
    notifyListeners();

    try {
      searchResults = await _repository.searchUsers(
        keyword: keyword.trim(),
        firebaseUid: firebaseUid,
      );
    } catch (e) {
      errorMessage = e.toString();
    }

    isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    searchResults = [];
    notifyListeners();
  }

  Future<Map<String, dynamic>?> createOrGetConversation({
    required String firebaseUid,
    required int targetUserId,
  }) async {
    try {
      final conversation = await _repository.createOrGetConversation(
        firebaseUid: firebaseUid,
        targetUserId: targetUserId,
      );

      await loadConversations(firebaseUid);
      return conversation;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> loadMessages({
    required int conversationId,
    required String firebaseUid,
  }) async {
    isLoadingMessages = true;
    errorMessage = null;
    isOtherUserTyping = false;
    notifyListeners();

    try {
      messages = await _repository.getMessages(
        conversationId: conversationId,
        firebaseUid: firebaseUid,
      );

      _messageIds.clear();

      for (final message in messages) {
        final id = _toInt(message['id']);
        if (id != null) {
          _messageIds.add(id);
        }
      }

      await _repository.markAsRead(
        conversationId: conversationId,
        firebaseUid: firebaseUid,
      );

      _setConversationUnreadCount(conversationId, 0);
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoadingMessages = false;
    notifyListeners();
  }

  Future<void> sendMessage({
    required int conversationId,
    required String firebaseUid,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;

    isSending = true;
    errorMessage = null;
    notifyListeners();

    try {
      emitStopTyping(
        conversationId: conversationId,
        firebaseUid: firebaseUid,
      );

      final newMessage = await _repository.sendMessage(
        conversationId: conversationId,
        firebaseUid: firebaseUid,
        content: content,
      );

      if (_activeConversationId == conversationId) {
        _addMessageIfNew(newMessage);
      }

      await loadConversations(firebaseUid);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }

    isSending = false;
    notifyListeners();
  }

  void emitTyping({
    required int conversationId,
    required String firebaseUid,
  }) {
    _repository.emitTyping(
      conversationId: conversationId,
      firebaseUid: firebaseUid,
    );
  }

  void emitStopTyping({
    required int conversationId,
    required String firebaseUid,
  }) {
    _repository.emitStopTyping(
      conversationId: conversationId,
      firebaseUid: firebaseUid,
    );
  }

  void clearData() {
    conversations = [];
    searchResults = [];
    messages = [];

    isLoadingConversations = false;
    isSearching = false;
    isLoadingMessages = false;
    isSending = false;
    isSocketConnected = false;
    isOtherUserTyping = false;

    errorMessage = null;
    _currentFirebaseUid = null;
    _activeConversationId = null;
    _messageIds.clear();

    _repository.disposeSocket();

    notifyListeners();
  }

  @override
  void dispose() {
    _repository.disposeSocket();
    super.dispose();
  }
}