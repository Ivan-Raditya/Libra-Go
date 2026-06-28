import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class TripMapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> itineraries;
  final String destinationName;
  
  const TripMapScreen({
    super.key, 
    required this.itineraries,
    required this.destinationName,
  });

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  LatLng _center = const LatLng(-8.409518, 115.188919); // Default Bali
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoordinates();
  }

  Future<void> _fetchCoordinates() async {
    if (widget.destinationName == 'Destinasi' || widget.destinationName.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(widget.destinationName)}&format=json&limit=1');
      final response = await http.get(url, headers: {'User-Agent': 'LibraGoApp/1.0'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          
          if (mounted) {
            setState(() {
              _center = LatLng(lat, lon);
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      // Error handling fallthrough
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1E8F82)));
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 10.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.libra_go',
        ),
        MarkerLayer(
          markers: widget.itineraries.map((item) {
            // Placeholder offsets
            final offsetLat = (item['day_number'] ?? 0) * 0.05;
            return Marker(
              point: LatLng(_center.latitude + offsetLat, _center.longitude + offsetLat),
              width: 80,
              height: 80,
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            );
          }).toList(),
        ),
      ],
    );
  }
}
