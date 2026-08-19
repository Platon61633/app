import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../services/auth_service.dart';
import 'format_utils.dart';
import 'map.dart';
import 'my_orders_page.dart';
import 'profile.dart';
import 'services_page.dart';
import 'session_utils.dart';

/// Общий каркас главного экрана: нижняя навигация (Услуги / Мои заказы /
/// Профиль) и корзина, которая хранится здесь, а не в отдельных вкладках,
/// потому что переживает переключение между ними.
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({
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
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _selectedIndex = 0;
  final List<MapSelectionResult> _cartItems = [];

  void _addToCart(MapSelectionResult item) {
    setState(() {
      _cartItems.add(item);
      _selectedIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.serviceName} добавлено в корзину')),
    );
  }

  Future<void> _openCartModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submitCart() async {
              if (_cartItems.isEmpty) {
                Navigator.of(sheetContext).pop();
                return;
              }

              try {
                final headers = await AuthService.getAuthHeaders();
                final body = {
                  'description': 'Заказ из корзины',
                  'items': _cartItems.map((item) => item.toOrderItem()).toList(),
                };
                final response = await http.post(
                  ApiConfig.uri('/orders'),
                  headers: headers,
                  body: jsonEncode(body),
                );

                if (!mounted) return;

                if (response.statusCode >= 200 && response.statusCode < 300) {
                  setState(() {
                    _cartItems.clear();
                  });
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Заказ из корзины отправлен')),
                  );
                } else if (response.statusCode == 401) {
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Сессия истекла, войдите снова')),
                  );
                  await redirectToSignIn(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка сервера: ${response.statusCode}')),
                  );
                }
              } catch (error) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка отправки: $error')),
                );
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Корзина',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          onPressed: _cartItems.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    _cartItems.clear();
                                  });
                                  setSheetState(() {});
                                },
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_cartItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('Корзина пуста')),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 360),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _cartItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            final quantityLabel = item.serviceName == 'Спил'
                                ? 'Деревьев: ${item.area} шт'
                                : 'Площадь: ${item.area} м²';
                            return Card(
                              child: ListTile(
                                title: Text(item.serviceName),
                                subtitle: Text(
                                  '$quantityLabel\n${formatDateTimeRu(item.scheduledAt)}\n${item.address}',
                                ),
                                isThreeLine: true,
                                trailing: Text('${item.price} ₽'),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _cartItems.isEmpty ? null : submitCart,
                            child: const Text('Оформить'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      ServicesPage(
        cartCount: _cartItems.length,
        onCartPressed: _openCartModal,
        onServiceSelected: _addToCart,
      ),
      const MyOrdersPage(),
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
            icon: Icon(Icons.miscellaneous_services_rounded),
            label: 'Услуги',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Мои заказы',
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
