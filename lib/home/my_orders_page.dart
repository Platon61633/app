import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../services/auth_service.dart';
import 'format_utils.dart';
import 'order_summary.dart';
import 'session_utils.dart';

/// Вкладка "Мои заказы": список заявок пользователя с мини-картой площади
/// (если она есть у заказа).
class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  late Future<List<OrderSummary>> _ordersFuture;

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

  Future<List<OrderSummary>> _loadOrders() async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.get(
      ApiConfig.uri('/orders'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      // Токена нет или он истёк — возвращаем пользователя на экран входа
      // вместо того, чтобы просто показать ошибку.
      if (mounted) {
        await redirectToSignIn(context);
      }
      throw Exception('Сессия истекла, войдите снова');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.map((entry) => OrderSummary.fromJson(entry)).toList();
    }

    if (decoded is Map<String, dynamic>) {
      final rawItems = decoded['items'];
      if (rawItems is List) {
        return rawItems.map((entry) => OrderSummary.fromJson(entry)).toList();
      }
      final rawOrders = decoded['orders'];
      if (rawOrders is List) {
        return rawOrders.map((entry) => OrderSummary.fromJson(entry)).toList();
      }
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FutureBuilder<List<OrderSummary>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final error = snapshot.error;
          final orders = snapshot.data ?? const <OrderSummary>[];

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
                                                  // Мини-карта только для просмотра: жесты отключены,
                                                  // чтобы не мешать прокрутке списка заказов.
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
                                            Text(
                                              order.title == 'спил'
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

/// Заказ хранит время как обычную строку (см. `MapSelectionResult.toOrderItem`),
/// поэтому здесь пытаемся распарсить её обратно в DateTime и показать в
/// привычном виде "20 августа 2026, 14:30". Если распарсить не удалось
/// (старые/сторонние данные), показываем строку как есть.
String _formatOrderTime(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw;
  }
  return formatDateTimeRu(parsed);
}
