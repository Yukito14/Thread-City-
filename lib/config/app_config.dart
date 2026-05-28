class AppConfig {
  static const String ipAddress = '192.168.4.83';

  static const String socketUrl = 'http://$ipAddress:3000';
  static const String baseUrl = 'http://$ipAddress:3000/api';

  static const String authUrl = '$baseUrl/auth';
  static const String postsUrl = '$baseUrl/posts';
}