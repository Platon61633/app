import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  bool _selectMode = false;
  LatLng? _selectionStart;
  LatLng? _selectionEnd;
  List<LatLng> get _selectionPolygon {
    final a = _selectionStart;
    final b = _selectionEnd;
    if (a == null || b == null) return [];
    return [
      LatLng(a.latitude, a.longitude),
      LatLng(a.latitude, b.longitude),
      LatLng(b.latitude, b.longitude),
      LatLng(b.latitude, a.longitude),
    ];
  }

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
      appBar: AppBar(title: const Text('Map Screen')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(55.755793, 37.617134),
          initialZoom: 5,
          onTap: (tap, latlng) {
            if (!_selectMode) return;
            setState(() {
              if (_selectionStart == null) {
                _selectionStart = latlng;
                _selectionEnd = null;
              } else if (_selectionEnd == null) {
                _selectionEnd = latlng;
                _selectMode = false; // finish selection after second tap
                final bounds = LatLngBounds.fromPoints([_selectionStart!, _selectionEnd!]);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Выбрана область: ${bounds.southWest}, ${bounds.northEast}'),
                    duration: const Duration(seconds: 4),
                  ),
                );
              } else {
                _selectionStart = latlng;
                _selectionEnd = null;
              }
            });
          },
        ),
        children: [
          // Satellite imagery (Esri World Imagery)
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'com.example.flutter_map_example',
            maxZoom: 19,
            // attribution text removed: older flutter_map versions may not support attributionBuilder
          ),
          // Draw selection rectangle when available
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'select',
            onPressed: () {
              setState(() {
                _selectMode = true;
                _selectionStart = null;
                _selectionEnd = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Тапните на карту: два угла области')),
              );
            },
            child: const Icon(Icons.crop_square),
            tooltip: 'Выбрать область',
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'clear',
            onPressed: () {
              setState(() {
                _selectMode = false;
                _selectionStart = null;
                _selectionEnd = null;
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
