import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class SearchRepository {
  final String baseUrl = AppConfig.baseUrl;

  Future<Map<String, dynamic>> search(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/search').replace(
        queryParameters: {
          'q': query,
        },
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      throw Exception('Không thể tìm kiếm. Lỗi: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }
}