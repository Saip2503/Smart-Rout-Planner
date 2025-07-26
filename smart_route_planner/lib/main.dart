// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// IMPORTANT: Replace with your backend URL.
// Use 10.0.2.2 for Android emulator to connect to localhost on your machine.
// For a physical device, use your machine's local network IP (e.g., http://192.168.1.10:8000).
const String backendUrl = 'http://10.0.2.2:8000';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Route Planner',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Map state
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(19.0760, 72.8777), // Centered on Mumbai
    zoom: 12,
  );

  // Markers, polylines, and route logic
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _origin;
  LatLng? _destination;
  bool _isLoading = false;

  // Function to handle map taps to set origin and destination
  void _onMapTapped(LatLng location) {
    setState(() {
      if (_origin == null || (_origin != null && _destination != null)) {
        // Set origin
        _origin = location;
        _destination = null;
        _markers.clear();
        _polylines.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('origin'),
            position: _origin!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: const InfoWindow(title: 'Origin'),
          ),
        );
      } else {
        // Set destination and fetch route
        _destination = location;
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: _destination!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: const InfoWindow(title: 'Destination'),
          ),
        );
        _getRoute();
      }
    });
  }

  // Function to call the backend API and get the route
  Future<void> _getRoute() async {
    if (_origin == null || _destination == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/route'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'origin': {'lat': _origin!.latitude, 'lng': _origin!.longitude},
          'destination': {
            'lat': _destination!.latitude,
            'lng': _destination!.longitude,
          },
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> routeData = json.decode(response.body);
        final points = routeData
            .map((p) => LatLng(p['lat'], p['lng']))
            .toList();

        if (points.isNotEmpty) {
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: Colors.blue,
                width: 5,
              ),
            );
          });
        }
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching route: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to the server: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Route Planner'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        onTap: _onMapTapped,
        markers: _markers,
        polylines: _polylines,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _markers.clear();
            _polylines.clear();
            _origin = null;
            _destination = null;
          });
        },
        tooltip: 'Clear',
        child: const Icon(Icons.clear),
      ),
    );
  }
}
