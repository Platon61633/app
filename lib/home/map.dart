import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.serviceName});

  final String serviceName;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  bool _selectMode = false;
  // Points added by the user while selecting
  final List<LatLng> _points = [];
  // Current convex hull of _points (drawn as polygon)
  List<LatLng> _hull = [];
  DateTime? _selectedDateTime;

  List<LatLng> get _selectionPolygon => _hull;

  List<LatLng> get _mapPoints => const [
    LatLng(55.755793, 37.617134),
    LatLng(55.095960, 38.765519),
    LatLng(56.129038, 40.406502),
    LatLng(54.513645, 36.261268),
    LatLng(54.193122, 37.617177),
    LatLng(54.629540, 39.741809),
  ];

  @override
  void initState() {
    _mapController = MapController();
    super.initState();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: const Text('Укажите площадь для покоса'),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(47.285, 39.5),
              initialZoom: 15,
              onTap: (tap, latlng) {
                if (!_selectMode) return;
                setState(() {
                  if (_hull.length >= 3 && _pointInPolygon(latlng, _hull)) {
                    return;
                  }
                  _points.add(latlng);
                  if (_points.length >= 3) {
                    _hull = _convexHull(_points);
                  } else {
                    _hull = [];
                  }
                });
              },
            ),
            children: [
              // Satellite imagery (Esri World Imagery) — base layer
              TileLayer(
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.example.flutter_map_example',
                maxZoom: 19,
              ),

              // Labels overlay: Carto Light labels
              Opacity(
                opacity: 0.9,
                child: TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.flutter_map_example',
                ),
              ),

              // Markers for user-added points
              if (_points.isNotEmpty)
                MarkerLayer(
                  markers: _points
                      .map(
                        (p) => Marker(
                          width: 12,
                          height: 12,
                          point: p,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

              // Draw convex polygon when available
              if (_selectionPolygon.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _selectionPolygon,
                      color: Colors.blue.withOpacity(0.25),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
            ],
          ),

          // Confirm button fixed to bottom of the screen
          if (_hull.length >= 3)
            Positioned(
              left: 16,
              bottom: 24,
                child: FloatingActionButton.extended(
                  heroTag: 'confirm_bottom',
                  onPressed: () {
                    _showConfirmModal(context);
                  },
                  label: Text('Подтвердить ${_polygonAreaMeters(_hull).toStringAsFixed(0)} м²'),
                  icon: const Icon(Icons.check),
                ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Confirm button appears when hull has 3+ points
          
          // Start polygon selection: prompt and clear previous points
          FloatingActionButton(
            heroTag: 'select',
            onPressed: () {
              setState(() {
                _selectMode = true;
                _points.clear();
                _hull = [];
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Выберите 3 и более точек')),
              );
            },
            backgroundColor: _selectMode ? Colors.green : null,
            child: const Icon(Icons.crop_square),
            tooltip: 'Выбрать область (многоугольник)',
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'clear',
            onPressed: () {
              setState(() {
                _selectMode = false;
                _points.clear();
                _hull = [];
              });
            },
            child: const Icon(Icons.clear),
            tooltip: 'Очистить выделение',
          ),
        ],
      ),
    );
  }
}

// Geometry helpers
List<LatLng> _convexHull(List<LatLng> points) {
  if (points.length < 3) return [];
  // Convert to pairs (x=lon, y=lat)
  final pts = points
      .map((p) => _Point(p.longitude, p.latitude, p))
      .toList();
  pts.sort((a, b) {
    if (a.x == b.x) return a.y.compareTo(b.y);
    return a.x.compareTo(b.x);
  });

  List<_Point> lower = [];
  for (final p in pts) {
    while (lower.length >= 2 && _cross(lower[lower.length - 2], lower[lower.length - 1], p) <= 0) {
      lower.removeLast();
    }
    lower.add(p);
  }

  List<_Point> upper = [];
  for (final p in pts.reversed) {
    while (upper.length >= 2 && _cross(upper[upper.length - 2], upper[upper.length - 1], p) <= 0) {
      upper.removeLast();
    }
    upper.add(p);
  }

  // concatenate lower and upper to make full hull; skip last point of each (it's the start of the other)
  lower.removeLast();
  upper.removeLast();
  final hullPts = <LatLng>[];
  for (final p in lower) hullPts.add(p.orig);
  for (final p in upper) hullPts.add(p.orig);
  return hullPts;
}

double _cross(_Point o, _Point a, _Point b) {
  return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
}

class _Point {
  final double x;
  final double y;
  final LatLng orig;
  _Point(this.x, this.y, this.orig);
}

class MapSelectionResult {
  const MapSelectionResult({
    required this.serviceName,
    required this.area,
    required this.price,
    required this.address,
    required this.note,
    required this.scheduledAt,
  });

  final String serviceName;
  final int area;
  final int price;
  final String address;
  final String note;
  final DateTime scheduledAt;

  Map<String, dynamic> toOrderItem() {
    return {
      'name': serviceName.toLowerCase(),
      'work': area,
      'adres': address,
      'note': note,
      'time': scheduledAt.toString(),
      'cost': price,
    };
  }
}

bool _pointInPolygon(LatLng pt, List<LatLng> polygon) {
  // Ray casting algorithm
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final xi = polygon[i].longitude;
    final yi = polygon[i].latitude;
    final xj = polygon[j].longitude;
    final yj = polygon[j].latitude;

    final intersect = ((yi > pt.latitude) != (yj > pt.latitude)) &&
        (pt.longitude < (xj - xi) * (pt.latitude - yi) / (yj - yi + 0.0) + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}

double _polygonAreaMeters(List<LatLng> polygon) {
  if (polygon.length < 3) return 0.0;
  const double R = 6378137.0; // radius for WebMercator
  List<List<double>> pts = polygon
      .map((p) {
        final lon = p.longitude * math.pi / 180.0;
        final lat = p.latitude * math.pi / 180.0;
        final x = R * lon;
        final y = R * math.log(math.tan(math.pi / 4 + lat / 2));
        return [x, y];
      })
      .toList();
  // shoelace
  double area = 0.0;
  for (int i = 0; i < pts.length; i++) {
    final j = (i + 1) % pts.length;
    area += pts[i][0] * pts[j][1] - pts[j][0] * pts[i][1];
  }
  return area.abs() / 2.0; // in square meters (approx)
}

extension _Formatting on double {
  String rubString() => '${this.toStringAsFixed(0)}₽';
}

extension on _MapScreenState {
  void _showConfirmModal(BuildContext context) async {
    final area = _polygonAreaMeters(_hull);
    final price = (area * 5).round();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedAddress = _selectionCenterLabel(_points);
            DateTime? selectedDateTime = _selectedDateTime;
            final selectedDateText = selectedDateTime == null
                ? 'Время не выбрано'
                : _formatDateTimeRu(selectedDateTime);

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Итоговая площадь: ${area.toStringAsFixed(0)} м²', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Цена: ${price} рублей', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(ctx).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Адрес определяется автоматически', style: Theme.of(ctx).textTheme.labelMedium),
                          const SizedBox(height: 4),
                          Text(selectedAddress, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(ctx).dividerColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedDateText,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: ctx,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                final time = await showTimePicker(
                                  context: ctx,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  final pickedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                  setSheetState(() {
                                    selectedDateTime = pickedDateTime;
                                    _selectedDateTime = pickedDateTime;
                                  });
                                }
                              }
                            },
                            child: const Text('Выбрать время'),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (selectedDateTime == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите время')));
                                return;
                              }

                              final pickedDateTime = selectedDateTime;
                              final addr = _selectionCenterLabel(_points);
                              final note = _selectedPointsNote(_points);
                              final selection = MapSelectionResult(
                                serviceName: widget.serviceName,
                                area: area.round(),
                                price: price,
                                address: addr,
                                note: note,
                                scheduledAt: pickedDateTime!,
                              );

                              Navigator.of(ctx).pop();
                              if (mounted) {
                                Navigator.of(context).pop(selection);
                              }
                            },
                            child: const Text('Далее'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
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

String _selectionCenterLabel(List<LatLng> points) {
  if (points.isEmpty) return 'Координаты не выбраны';

  final latitude = points.map((point) => point.latitude).reduce((a, b) => a + b) / points.length;
  final longitude = points.map((point) => point.longitude).reduce((a, b) => a + b) / points.length;

  return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

String _selectedPointsNote(List<LatLng> points) {
  if (points.isEmpty) return 'Координаты не выбраны';

  return points
      .map((point) => '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}')
      .join('; ');
}
