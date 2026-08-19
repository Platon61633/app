import 'package:latlong2/latlong.dart';

/// Данные одного заказа для отображения на странице "Мои заказы".
/// Собирается из ответа `GET /orders` (см. backend/orders.js).
class OrderSummary {
  OrderSummary({
    required this.title,
    required this.work,
    required this.address,
    required this.note,
    required this.comment,
    required this.time,
    required this.cost,
    required this.status,
    required this.polygon,
  });

  final String title;
  final int work;
  final String address;
  final String note;
  final String comment;
  final String time;
  final int cost;
  final String status;
  // Вершины выделенной на карте площади (если удалось распарсить note).
  final List<LatLng> polygon;

  factory OrderSummary.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final items = json['items'];
      final firstItem = items is List && items.isNotEmpty && items.first is Map<String, dynamic>
          ? items.first as Map<String, dynamic>
          : json;

      final note = (firstItem['note'] ?? json['note'] ?? '').toString();

      return OrderSummary(
        title: (firstItem['name'] ?? json['title'] ?? json['description'] ?? 'Заказ').toString(),
        work: _readInt(firstItem['work'] ?? json['work'] ?? 0),
        address: (firstItem['adres'] ?? json['adres'] ?? '').toString(),
        note: note,
        comment: (firstItem['comment'] ?? json['comment'] ?? '').toString(),
        time: (firstItem['time'] ?? json['time'] ?? '').toString(),
        cost: _readInt(firstItem['cost'] ?? json['cost'] ?? 0),
        status: (json['status'] ?? '').toString(),
        polygon: _parseNotePolygon(note),
      );
    }

    return OrderSummary(
      title: 'Заказ',
      work: 0,
      address: '',
      note: '',
      comment: '',
      time: '',
      cost: 0,
      status: '',
      polygon: const [],
    );
  }
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value.toString()) ?? 0;
}

/// Разбирает строку вида "lat, lon; lat, lon; ..." (см. map.dart,
/// `_selectedPointsNote`) в список точек многоугольника. Возвращает
/// пустой список, если координат меньше трёх или строка нечитаема —
/// тогда мини-карта просто не показывается.
List<LatLng> _parseNotePolygon(String note) {
  if (note.trim().isEmpty) {
    return const [];
  }

  final points = <LatLng>[];
  for (final part in note.split(';')) {
    final coords = part.trim().split(',');
    if (coords.length != 2) {
      continue;
    }
    final lat = double.tryParse(coords[0].trim());
    final lon = double.tryParse(coords[1].trim());
    if (lat == null || lon == null) {
      continue;
    }
    points.add(LatLng(lat, lon));
  }

  return points.length >= 3 ? points : const [];
}
