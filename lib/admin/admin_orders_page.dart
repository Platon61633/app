import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import '../home/format_utils.dart';
import '../home/session_utils.dart';
import '../services/api_config.dart';
import '../services/auth_service.dart';
import 'admin_order_summary.dart';

/// Вкладка администратора "Заказы": список заявок ВСЕХ пользователей
/// (обычный клиент видит только свои — см. `home/my_orders_page.dart`).
class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  late Future<List<AdminOrderSummary>> _ordersFuture;

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

  Future<List<AdminOrderSummary>> _loadOrders() async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.get(
      ApiConfig.uri('/admin/orders'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      if (mounted) {
        await redirectToSignIn(context);
      }
      throw Exception('Сессия истекла, войдите снова');
    }

    if (response.statusCode == 403) {
      throw Exception('Доступ только для администратора');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.map((entry) => AdminOrderSummary.fromJson(entry)).toList();
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FutureBuilder<List<AdminOrderSummary>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final error = snapshot.error;
          final orders = snapshot.data ?? const <AdminOrderSummary>[];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Заказы всех пользователей',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Все заявки, оформленные в приложении',
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
                                        'Заказов пока нет',
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
                                    final hasAreaMap = order.polygon.length >= 3;
                                    return Card(
                                      elevation: 8,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (hasAreaMap) ...[
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(14),
                                                child: SizedBox(
                                                  height: 140,
                                                  child: IgnorePointer(
                                                    child: FlutterMap(
                                                      options: MapOptions(
                                                        initialCameraFit: CameraFit.bounds(
                                                          bounds: LatLngBounds.fromPoints(order.polygon),
                                                          padding: const EdgeInsets.all(28),
                                                        ),
                                                        interactionOptions: const InteractionOptions(
                                                          flags: InteractiveFlag.none,
                                                        ),
                                                      ),
                                                      children: [
                                                        TileLayer(
                                                          urlTemplate:
                                                              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                                                          userAgentPackageName: 'com.example.app',
                                                          maxZoom: 19,
                                                        ),
                                                        PolygonLayer(
                                                          polygons: [
                                                            Polygon(
                                                              points: order.polygon,
                                                              color: Colors.blue.withOpacity(0.25),
                                                              borderColor: Colors.blue,
                                                              borderStrokeWidth: 2,
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                            ],
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
                                            if (order.customerName.isNotEmpty) ...[
                                              Text('Клиент: ${order.customerName}'),
                                              const SizedBox(height: 4),
                                            ],
                                            if (order.userEmail.isNotEmpty) ...[
                                              Text('Email: ${order.userEmail}'),
                                              const SizedBox(height: 4),
                                            ],
                                            if (order.customerPhone.isNotEmpty) ...[
                                              Text('Телефон: ${order.customerPhone}'),
                                              const SizedBox(height: 4),
                                            ],
                                            Text(
                                              order.title.toLowerCase() == 'спил'
                                                  ? 'Деревьев: ${order.work} шт.'
                                                  : 'Площадь: ${order.work} м²',
                                            ),
                                            if (!hasAreaMap && order.note.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text('Координаты: ${order.note}'),
                                            ],
                                            if (order.address.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text('Адрес: ${order.address}'),
                                            ],
                                            if (order.time.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text('Время: ${_formatOrderTime(order.time)}'),
                                            ],
                                            if (order.comment.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text('Комментарий: ${order.comment}'),
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

String _formatOrderTime(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw;
  }
  return formatDateTimeRu(parsed);
}
