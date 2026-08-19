import 'package:flutter/material.dart';

import '../home/profile.dart';
import 'admin_orders_page.dart';
import 'workers_page.dart';

/// Каркас раздела администратора: нижняя навигация "Заказы / Рабочие /
/// Профиль". Аналог `home/home_shell.dart` для роли admin — без корзины и
/// списка услуг, которые нужны только заказчику.
class AdminShellPage extends StatefulWidget {
  const AdminShellPage({
    super.key,
    required this.role,
    required this.name,
    required this.email,
    required this.phone,
    required this.token,
  });

  final String role;
  final String name;
  final String email;
  final String phone;
  final String? token;

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const AdminOrdersPage(),
      const WorkersPage(),
      ProfilePage(
        role: widget.role,
        name: widget.name,
        email: widget.email,
        phone: widget.phone,
        token: widget.token,
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF164E63), Color(0xFF0EA5A5)],
          ),
        ),
        child: SafeArea(
          child: IndexedStack(index: _selectedIndex, children: pages),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Заказы',
          ),
          NavigationDestination(
            icon: Icon(Icons.engineering_rounded),
            label: 'Рабочие',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
