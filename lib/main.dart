import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/admin_shell.dart';
import 'home/base.dart';
import 'auth/signin.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String _role = 'user';
  String _name = 'Пользователь';
  String _email = '';
  String _phone = '';
  // String _story = '';
  String? _token;

  @override
  void initState() {
    super.initState();
    _checkStoredSession();
  }

  Future<void> _checkStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    final name = prefs.getString('user_name');
    final email = prefs.getString('user_email');
    final phone = prefs.getString('user_phone');
    // final story = prefs.getString('story');
    final token = prefs.getString('auth_token') ?? prefs.getString('token');

    // Пользователь считается авторизованным, только если есть токен —
    // без него запросы к серверу всё равно будут падать с 401.
    final hasValidToken = token != null && token.isNotEmpty;
    if (!hasValidToken && (role != null || name != null || email != null)) {
      // Токена нет (не сохранился или истёк), но остались данные прошлой
      // сессии — сбрасываем их, чтобы не показывать пользователя
      // залогиненным, когда это не так.
      await AuthService.clear();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isAuthenticated = hasValidToken;
      _role = role ?? 'user';
      _name = name ?? 'Пользовательi';
      _email = email ?? '';
      _phone = phone ?? '';
      // _story = story ?? '';
      _token = hasValidToken ? token : null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokos Spil Story',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F6F8B)),
        useMaterial3: true,
      ),
      home: _isAuthenticated
          ? _buildShellForRole(
              role: _role,
              name: _name,
              email: _email,
              phone: _phone,
              token: _token,
            )
          : const SignInPage(),
      routes: {
        '/signin': (ctx) => const SignInPage(),
        '/home': (ctx) {
          // Наименованный маршрут для возврата на главный экран.
          // Загружаем сохранённые данные из SharedPreferences перед созданием HomeShellPage.
          return FutureBuilder(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final prefs = snapshot.data as SharedPreferences;
              for (final key in prefs.getKeys()) {
                print('$key: ${prefs.get(key)}');
              }
              final token =
                  prefs.getString('auth_token') ?? prefs.getString('token');
              if (token == null || token.isEmpty) {
                // Токена нет — на "домашний" маршрут пускать нельзя,
                // иначе запросы к серверу будут падать с 401.
                return const SignInPage();
              }
              final role = prefs.getString('user_role') ?? 'user';
              final name = prefs.getString('user_name') ?? 'Пользовательt';
              final email = prefs.getString('user_email') ?? '';
              final phone = prefs.getString('user_phone') ?? '';
              return _buildShellForRole(
                role: role,
                name: name,
                email: email,
                phone: phone,
                token: token,
              );
            },
          );
        },
        // '/map': (ctx) => CastomMap()
      },
    );
  }
}

/// Приложение меняется в зависимости от роли пользователя: администратор
/// (role == 'admin') видит раздел с заказами всех пользователей и списком
/// рабочих вместо привычного заказчику каталога услуг. Регистрация с ролью
/// admin в приложении не предусмотрена — такой аккаунт заводится напрямую
/// в БД (`UPDATE users SET role = 'admin' WHERE email = '...';`), поэтому
/// единственный способ увидеть AdminShellPage — войти уже готовым админом.
Widget _buildShellForRole({
  required String role,
  required String name,
  required String email,
  required String phone,
  required String? token,
}) {
  if (role == 'admin') {
    return AdminShellPage(
      role: role,
      name: name,
      email: email,
      phone: phone,
      token: token,
    );
  }

  // Роль "worker" отдельного интерфейса пока не имеет и использует тот же
  // экран, что и заказчик.
  return HomeShellPage(
    role: role,
    name: name,
    email: email,
    phone: phone,
    token: token,
  );
}
