import 'dart:convert';

import 'package:app/home/map.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

import 'profile.dart';

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
                  Uri.parse('http://192.168.1.53:5000/orders'),
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
                            return Card(
                              child: ListTile(
                                title: Text(item.serviceName),
                                subtitle: Text(
                                  'Площадь: ${item.area} м²\n${_formatDateTimeRu(item.scheduledAt)}\n${item.address}',
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

class ServicesPage extends StatelessWidget {
  const ServicesPage({
    super.key,
    required this.cartCount,
    required this.onCartPressed,
    required this.onServiceSelected,
  });

  final int cartCount;
  final VoidCallback onCartPressed;
  final ValueChanged<MapSelectionResult> onServiceSelected;

  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceCard(
        title: 'Покос',
        subtitle: 'Профессиональная услуга по покосу травы и кустарников',
        icon: Icons.grass_rounded,
        onSelected: onServiceSelected,
      ),
      _ServiceCard(
        title: 'Спил',
        subtitle: 'Удаление деревьев и безопасный спил стволов',
        icon: Icons.forest_rounded,
        onSelected: onServiceSelected,
      ),
      _ServiceCard(
        title: 'Строй',
        subtitle: 'Строительные работы и благоустройство участка',
        icon: Icons.construction_rounded,
        onSelected: onServiceSelected,
      ),
    ];

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 52),
                  const Text(
                    'Услуги',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Выберите нужную услугу',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...services.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: service,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: SafeArea(
            child: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: IconButton.filled(
                onPressed: onCartPressed,
                icon: const Icon(Icons.shopping_cart_rounded),
                tooltip: 'Корзина',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<MapSelectionResult> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final result = await Navigator.push<MapSelectionResult>(
            context,
            MaterialPageRoute(builder: (_) => MapScreen(serviceName: title)),
          );
          if (result != null && context.mounted) {
            onSelected(result);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F6F8B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 30, color: const Color(0xFF1F6F8B)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  late Future<List<_OrderSummary>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<void> _refresh() async {
    setState(() {
      _ordersFuture = _loadOrders();
    });
    await _ordersFuture;
  }

  Future<List<_OrderSummary>> _loadOrders() async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('http://192.168.1.53:5000/orders'),
      headers: headers,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.map((entry) => _OrderSummary.fromJson(entry)).toList();
    }

    if (decoded is Map<String, dynamic>) {
      final rawItems = decoded['items'];
      if (rawItems is List) {
        return rawItems.map((entry) => _OrderSummary.fromJson(entry)).toList();
      }
      final rawOrders = decoded['orders'];
      if (rawOrders is List) {
        return rawOrders.map((entry) => _OrderSummary.fromJson(entry)).toList();
      }
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FutureBuilder<List<_OrderSummary>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final error = snapshot.error;
          final orders = snapshot.data ?? const <_OrderSummary>[];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Мои заказы',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'История ваших оформленных заявок',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : error != null
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 120),
                                Center(
                                  child: Text(
                                    'Не удалось загрузить заказы\n$error',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            )
                          : orders.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: 120),
                                    Center(
                                      child: Text(
                                        'Пока нет заказов',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: orders.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final order = orders[index];
                                    return Card(
                                      elevation: 8,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    order.title,
                                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                                  ),
                                                ),
                                                Text('${order.cost} ₽'),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text('Площадь: ${order.work} м²'),
                                            if (order.note.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text('Координаты: ${order.note}'),
                                            ],
                                            if (order.address.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text('Адрес: ${order.address}'),
                                            ],
                                            if (order.time.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text('Время: ${order.time}'),
                                            ],
                                            if (order.status.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text('Статус: ${order.status}'),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderSummary {
  _OrderSummary({
    required this.title,
    required this.work,
    required this.address,
    required this.note,
    required this.time,
    required this.cost,
    required this.status,
  });

  final String title;
  final int work;
  final String address;
  final String note;
  final String time;
  final int cost;
  final String status;

  factory _OrderSummary.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final items = json['items'];
      final firstItem = items is List && items.isNotEmpty && items.first is Map<String, dynamic>
          ? items.first as Map<String, dynamic>
          : json;

      return _OrderSummary(
        title: (firstItem['name'] ?? json['title'] ?? json['description'] ?? 'Заказ').toString(),
        work: _readInt(firstItem['work'] ?? json['work'] ?? 0),
        address: (firstItem['adres'] ?? json['adres'] ?? '').toString(),
        note: (firstItem['note'] ?? json['note'] ?? '').toString(),
        time: (firstItem['time'] ?? json['time'] ?? '').toString(),
        cost: _readInt(firstItem['cost'] ?? json['cost'] ?? 0),
        status: (json['status'] ?? '').toString(),
      );
    }

    return _OrderSummary(
      title: 'Заказ',
      work: 0,
      address: '',
      note: '',
      time: '',
      cost: 0,
      status: '',
    );
  }
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value.toString()) ?? 0;
}

String _formatDateTimeRu(DateTime value) {
  const months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day ${months[value.month - 1]} ${value.year}, $hour:$minute';
}
