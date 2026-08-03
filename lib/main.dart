import 'package:app/home/map.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home/base.dart';
import 'auth/signin.dart';

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
  String _story = '';
  String? _token;

  @override
  void initState() {
    super.initState();
    _checkStoredSession();
  }

  Future<void> _checkStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    final name = prefs.getString('name');
    final email = prefs.getString('email');
    final phone = prefs.getString('phone');
    final story = prefs.getString('story');
    final token = prefs.getString('auth_token') ?? prefs.getString('token');

    if (!mounted) {
      return;
    }

    setState(() {
      _isAuthenticated = role != null || name != null || email != null || token != null;
      _role = role ?? 'user';
      _name = name ?? 'Пользователь';
      _email = email ?? '';
      _phone = phone ?? '';
      _story = story ?? '';
      _token = token;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
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
          ? HomeShellPage(
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
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              final prefs = snapshot.data as SharedPreferences;
              final role = prefs.getString('role') ?? 'user';
              final name = prefs.getString('name') ?? 'Пользователь';
              final email = prefs.getString('email') ?? '';
              final phone = prefs.getString('phone') ?? '';
              final token = prefs.getString('auth_token') ?? prefs.getString('token');
              return HomeShellPage(role: role, name: name, email: email, phone: phone, token: token);
            },
          );
        },
        // '/map': (ctx) => CastomMap()
      },
    );
  }
}
