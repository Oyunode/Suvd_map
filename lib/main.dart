import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapSearchScreen(),
    );
  }
}

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  final MapController mapController = MapController();

  // 📍 Чиний өгсөн байршил
  static const LatLng fixedLocation =
      LatLng(47.9091350751498, 106.92308814612687);

  // 🔴 Анхнаасаа харагдах marker
  List<Marker> markers = [
    Marker(
      point: fixedLocation,
      width: 50,
      height: 50,
      child: const Icon(
        Icons.location_pin,
        color: Colors.red,
        size: 44,
      ),
    ),
  ];

  /// 🔎 SEARCH PLACE (COUNTRY / CITY / PLACE)
  Future<void> searchPlace(String query) async {
    if (query.trim().isEmpty) return;

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=$query'
      '&format=json'
      '&addressdetails=1'
      '&limit=1',
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'map_lab_flutter_app',
        'Accept-Language': 'en',
      },
    );

    if (response.statusCode != 200) return;

    final List data = json.decode(response.body);
    if (data.isEmpty) return;

    final item = data.first;

    final lat = double.parse(item['lat']);
    final lon = double.parse(item['lon']);
    final center = LatLng(lat, lon);

    // 📦 bounding box: [south, north, west, east]
    final List bbox = item['boundingbox'];
    final south = double.parse(bbox[0]);
    final north = double.parse(bbox[1]);
    final west = double.parse(bbox[2]);
    final east = double.parse(bbox[3]);

    setState(() {
      markers = [
        Marker(
          point: center,
          width: 50,
          height: 50,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 44,
          ),
        ),
      ];
    });

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(south, west),
          LatLng(north, east),
        ),
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenStreetMap Search'),
      ),
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search country, city, place',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: searchPlace,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => searchPlace(searchCtrl.text),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ),

          // 🗺 MAP
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: const MapOptions(
                initialCenter: fixedLocation, // 📍 ЭНД ТӨВЛӨРНӨ
                initialZoom: 17, // барилга түвшин
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.map_lab',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
