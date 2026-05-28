import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/search_repository.dart';

class SearchProvider extends ChangeNotifier {
  final SearchRepository searchRepository;

  SearchProvider(this.searchRepository);

  Timer? _debounce;

  String query = '';
  bool isLoading = false;
  String? errorMessage;

  List<dynamic> users = [];
  List<dynamic> posts = [];
  List<dynamic> hashtags = [];

  bool get hasQuery => query.trim().isNotEmpty;

  bool get hasResults {
    return users.isNotEmpty || posts.isNotEmpty || hashtags.isNotEmpty;
  }

  void onQueryChanged(String value) {
    query = value.trim();
    errorMessage = null;

    _debounce?.cancel();

    if (query.isEmpty) {
      users = [];
      posts = [];
      hashtags = [];
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    _debounce = Timer(const Duration(milliseconds: 450), () {
      search(query);
    });
  }

  Future<void> search(String keyword) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final data = await searchRepository.search(keyword);

      users = List<dynamic>.from(data['users'] ?? []);
      posts = List<dynamic>.from(data['posts'] ?? []);
      hashtags = List<dynamic>.from(data['hashtags'] ?? []);
    } catch (e) {
      errorMessage = 'Không thể tìm kiếm. Vui lòng thử lại.';
      users = [];
      posts = [];
      hashtags = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _debounce?.cancel();

    query = '';
    users = [];
    posts = [];
    hashtags = [];
    errorMessage = null;
    isLoading = false;

    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}