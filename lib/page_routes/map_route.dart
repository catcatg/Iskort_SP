import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapRoutePage extends StatefulWidget {
  const MapRoutePage({super.key});

  @override
  State<MapRoutePage> createState() => _MapRoutePageState();
}

class _MapRoutePageState extends State<MapRoutePage> {
  final MapController _mapController = MapController();
  final Location _locationService = Location();
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  LatLng? _userDestination;
  LatLng? _userLocation;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    if (!await _checkPermissions()) return;

    _locationService.onLocationChanged.listen((LocationData locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _userLocation = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );
          isLoading = false;
        });
      }
    });
  }

  Future<void> fetchCoordPoint(String location) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$location&format=json&limit=1',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        setState(() {
          _userDestination = LatLng(lat, lon);
        });
        await _fetchRoute();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Location not found.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching location data.')),
      );
    }
  }

  Future<void> _fetchRoute() async {
    if (_userLocation == null || _userDestination == null) return;

    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/${_userLocation!.longitude},${_userLocation!.latitude};${_userDestination!.longitude},${_userDestination!.latitude}?overview=full&geometries=polyline',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final geometry = data['routes'][0]['geometry'];
      _decodePolyline(geometry);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching route data.')),
      );
    }
  }

  void _decodePolyline(String encodedPolyline) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(encodedPolyline);
    setState(() {
      _routePoints =
          result
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
    });
  }

  // Check location permissions of user
  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }
    return true;
  }

  Future<void> _getUserLocation() async {
    try {
      final current = await _locationService.getLocation();
      if (current.latitude != null && current.longitude != null) {
        final pos = LatLng(current.latitude!, current.longitude!);
        setState(() => _userLocation = pos);

        // Move camera to user
        _mapController.move(pos, 15);

        // If destination exists, redraw the route
        if (_userDestination != null) {
          await _fetchRoute();
        }
      } else {
        throw Exception("No coordinates");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User location not available.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.red,
        title: const Text("Map"),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              // Set initial center to Panay island
              initialCenter: _userLocation ?? const LatLng(11.0, 122.5),
              initialZoom: 15,
              minZoom: 1,
              maxZoom: 100,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              CurrentLocationLayer(
                alignPositionOnUpdate: AlignOnUpdate.always,
                //focalPoint: FocalPoint.center,
                style: const LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    child: Icon(
                      Icons.location_pin,
                      color: Color.fromARGB(255, 150, 29, 20),
                    ),
                  ),
                  markerSize: Size(0, 0),
                  markerDirection: MarkerDirection.heading,
                ),
              ),
              if (_userDestination != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userDestination!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_on,
                        color: Color.fromARGB(255, 26, 91, 28),
                        size: 40,
                      ),
                    ),
                  ],
                ),
              if (_userLocation != null && _routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Enter destination',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 0.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      fetchCoordPoint(_searchController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 150, 29, 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                    child: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        onPressed: _getUserLocation,
        backgroundColor: const Color.fromARGB(255, 5, 41, 5),
        child: const Icon(
          Icons.my_location,
          color: Color.fromARGB(255, 150, 29, 20),
        ),
      ),
    );
  }
}
