import 'package:latlong2/latlong.dart';

/// Данные одного заказа для раздела администратора (см. `GET /admin/orders`
/// в backend/admin.js). Отличается от `home/order_summary.dart` тем, что
/// дополнительно содержит данные о клиенте, оформившем заказ — обычным
/// пользователям это видеть не нужно, поэтому вынесено в отдельную модель,
/// а не в общий файл.
class AdminOrderSummary {
  AdminOrderSummary({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.customerName,
    required this.customerPhone,
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

  final int id;
  final int? userId;
  final String userEmail;
  final String customerName;
  final String customerPhone;
  final String title;
  final int work;
  final String address;
  final String note;
  final String comment;
  final String time;
  final int cost;
  final String status;
  final List<LatLng> polygon;

  factory AdminOrderSummary.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final note = (json['note'] ?? '').toString();

      return AdminOrderSummary(
        id: _readInt(json['id']),
        userId: json['userId'] == null ? null : _readInt(json['userId']),
        userEmail: (json['userEmail'] ?? '').toString(),
        customerName: (json['customerName'] ?? '').toString(),
        customerPhone: (json['customerPhone'] ?? '').toString(),
        title: (json['name'] ?? 'Заказ').toString(),
        work: _readInt(json['work'] ?? 0),
        address: (json['adres'] ?? '').toString(),
        note: note,
        comment: (json['comment'] ?? '').toString(),
        time: (json['time'] ?? '').toString(),
        cost: _readInt(json['cost'] ?? 0),
        status: (json['status'] ?? '').toString(),
        polygon: _parseNotePolygon(note),
      );
    }

    return AdminOrderSummary(
      id: 0,
      userId: null,
      userEmail: '',
      customerName: '',
      customerPhone: '',
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

/// Та же логика разбора координат, что и в `home/order_summary.dart`
/// (приватная там функция недоступна отсюда, поэтому продублирована).
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
