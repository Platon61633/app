/// Централизованные настройки подключения к серверу.
///
/// Меняйте IP-адрес / порт сервера только здесь — все запросы в приложении
/// используют этот файл, поэтому обновлять адрес в нескольких местах
/// больше не нужно.
class ApiConfig {
  ApiConfig._();

  /// IP-адрес (или хост) сервера бэкенда.
  static const String serverHost = '192.168.0.110';
  // static const String serverHost = 'localhost';

  /// Порт сервера бэкенда.
  static const int serverPort = 5000;

  /// Базовый URL вида http://<serverHost>:<serverPort>
  static const String baseUrl = 'http://$serverHost:$serverPort';

  /// Собирает полный [Uri] для указанного пути, например:
  /// `ApiConfig.uri('/login')` -> `http://192.168.0.93:5000/login`
  static Uri uri(String path) => Uri.parse('$baseUrl$path');
}
