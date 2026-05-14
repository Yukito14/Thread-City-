import 'package:flutter/material.dart';
import '../repositories/message_repository.dart';

class MessageProvider extends ChangeNotifier {
  final MessageRepository _repository;

  MessageProvider(this._repository);

  List<Map<String, dynamic>> conversations = [];
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> messages = [];

  bool isLoadingConversations = false;
  bool isSearching = false;
  bool isLoadingMessages = false;
  bool isSending = false;

  String? errorMessage;

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
    notifyListeners();

    try {
      messages = await _repository.getMessages(
        conversationId: conversationId,
        firebaseUid: firebaseUid,
      );

      await _repository.markAsRead(
        conversationId: conversationId,
        firebaseUid: firebaseUid,
      );
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
    notifyListeners();

    try {
      final newMessage = await _repository.sendMessage(
        conversationId: conversationId,
        firebaseUid: firebaseUid,
        content: content,
      );

      messages.add(newMessage);
      await loadConversations(firebaseUid);
    } catch (e) {
      errorMessage = e.toString();
    }

    isSending = false;
    notifyListeners();
  }
}