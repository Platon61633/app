import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyUserPhone = 'user_phone';
  static const _keyUserRole = 'user_role';

  static Future<void> saveAuth({required String token, required Map<String, dynamic> user}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    if (user.containsKey('id')) await prefs.setInt(_keyUserId, user['id'] as int);
    if (user.containsKey('name')) await prefs.setString(_keyUserName, user['name'] as String);
    if (user.containsKey('phone')) await prefs.setString(_keyUserPhone, user['phone'] as String);
    if (user.containsKey('role')) await prefs.setString(_keyUserRole, user['role'] as String);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token == null) return {'Content-Type': 'application/json'};
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserPhone);
    await prefs.remove(_keyUserRole);
  }
}
