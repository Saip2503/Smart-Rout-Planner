// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// IMPORTANT: Replace with your backend URL.
const String backendUrl = 'http://10.0.2.2:8000';
// API Key will now be loaded from the .env file
final String googleApiKey =
    dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_DEFAULT_API_KEY';

Future<void> main() async {
  // Ensure that widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Load the .env file
  await dotenv.load(fileName: ".env");
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
  bool _isLocationPermissionGranted = false;
  final PolylinePoints _polylinePoints = PolylinePoints();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      setState(() {
        _isLocationPermissionGranted = true;
      });
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      if (_origin == null || (_origin != null && _destination != null)) {
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

  Future<void> _getRoute() async {
    if (_origin == null || _destination == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Get the optimized waypoint route from our Neo4j backend
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
        final dynamic decodedBody = json.decode(response.body);
        if (decodedBody is List && decodedBody.length >= 2) {
          List<LatLng> waypoints = decodedBody
              .map((p) => LatLng(p['lat'], p['lng']))
              .toList();

          // --- NEW: Limit the number of waypoints to avoid API errors ---
          const int maxWaypoints =
              23; // Google Directions API limit is 25 (origin + destination + 23 waypoints)
          if (waypoints.length > maxWaypoints) {
            final List<LatLng> simplifiedWaypoints = [];
            // Always include the start point
            simplifiedWaypoints.add(waypoints.first);

            // Calculate the step to pick points evenly
            final int step = (waypoints.length - 2) ~/ (maxWaypoints - 2);

            // Pick intermediate points
            for (int i = 1; i < waypoints.length - 1; i += step) {
              if (simplifiedWaypoints.length < maxWaypoints - 1) {
                simplifiedWaypoints.add(waypoints[i]);
              }
            }

            // Always include the end point
            simplifiedWaypoints.add(waypoints.last);
            waypoints = simplifiedWaypoints;
          }

          // 2. Get the detailed, road-snapped route from Google Directions API
          final PolylineResult result = await _polylinePoints
              .getRouteBetweenCoordinates(
                request: PolylineRequest(
                  origin: PointLatLng(
                    waypoints.first.latitude,
                    waypoints.first.longitude,
                  ),
                  destination: PointLatLng(
                    waypoints.last.latitude,
                    waypoints.last.longitude,
                  ),
                  mode: TravelMode.driving,
                  wayPoints: waypoints
                      .sublist(1, waypoints.length - 1)
                      .map(
                        (latlng) => PolylineWayPoint(
                          location: "${latlng.latitude},${latlng.longitude}",
                        ),
                      )
                      .toList(),
                ),
                googleApiKey: googleApiKey,
              );

          if (result.points.isNotEmpty) {
            final List<LatLng> polylineCoordinates = result.points
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();

            setState(() {
              _polylines.add(
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: polylineCoordinates,
                  color: Colors.deepOrange,
                  width: 6,
                ),
              );
            });
          } else {
            throw Exception(
              'Could not get route from Google Directions API: ${result.errorMessage}',
            );
          }
        } else {
          throw Exception('Invalid waypoint data from server.');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error fetching route from backend: ${response.body}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
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
        myLocationEnabled: _isLocationPermissionGranted,
        myLocationButtonEnabled: _isLocationPermissionGranted,
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
