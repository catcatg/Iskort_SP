import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isSearching = false;
  String _loadingMessage = '';
  LatLng? _userDestination;
  LatLng? _userLocation;
  List<LatLng> _routePoints = [];

  // Autocomplete
  List<Map<String, dynamic>> _searchSuggestions = [];
  Timer? _debounce;

  // Route info
  double? _distanceKm;
  double? _durationMin;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadLastDestination();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Load last destination from local storage
  Future<void> _loadLastDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('last_destination');
    if (last != null && mounted) {
      _searchController.text = last;
      await fetchCoordPoint(last, moveCamera: false);
    }
  }

  // Save destination
  Future<void> _saveLastDestination(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_destination', location);
  }

  // initialize location
  Future<void> _initLocation() async {
    if (!await _checkPermissions()) return;

    _locationService.onLocationChanged.listen((LocationData locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        if (!mounted) return;
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

  Future<void> fetchCoordPoint(
    String location, {
    bool moveCamera = true,
  }) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$location&format=json&limit=1',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          if (!mounted) return;
          setState(() {
            _userDestination = LatLng(lat, lon);
            _searchSuggestions.clear();
          });
          if (moveCamera) _mapController.move(_userDestination!, 18);
          await _fetchRoute();
          _saveLastDestination(location);
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      final distance = data['routes'][0]['distance'] / 1000; // km
      final duration = data['routes'][0]['duration'] / 60; // min
      _decodePolyline(geometry);
      if (!mounted) return;
      setState(() {
        _distanceKm = distance;
        _durationMin = duration;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching route data.')),
      );
    }
  }

  void _decodePolyline(String encodedPolyline) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(encodedPolyline);
    if (!mounted) return;
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
        if (!mounted) return;
        setState(() => _userLocation = pos);
        _mapController.move(pos, 18);
        if (_userDestination != null) await _fetchRoute();
      } else {
        throw Exception("No coordinates");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User location not available.')),
      );
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() => _searchSuggestions.clear());
      return;
    }

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!mounted) return;
      setState(
        () => _searchSuggestions = List<Map<String, dynamic>>.from(data),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text("Iskort Map"),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Color.fromARGB(255, 150, 29, 20),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? const LatLng(11.0, 122.5),
              initialZoom: 18,
              minZoom: 1,
              maxZoom: 100,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              CurrentLocationLayer(
                alignPositionOnUpdate: AlignOnUpdate.always,
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
                      strokeWidth: 5.0,
                      color: Color.fromARGB(255, 26, 91, 28),
                    ),
                  ],
                ),
            ],
          ),

          // Search bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
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
                            suffixIcon:
                                (_searchController.text.isNotEmpty)
                                    ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        if (!mounted) return;
                                        setState(() {
                                          _searchController.clear();
                                          _routePoints.clear();
                                          _userDestination = null;
                                          _distanceKm = null;
                                          _durationMin = null;
                                          _searchSuggestions.clear();
                                        });
                                      },
                                    )
                                    : null,
                          ),
                          onChanged: (value) {
                            if (!mounted) return;
                            setState(() {});
                            if (_debounce?.isActive ?? false)
                              _debounce!.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 500),
                              () => _fetchSuggestions(value),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          final destination = _searchController.text.trim();

                          if (destination.isEmpty) {
                            if (!mounted) return;
                            setState(() {
                              _routePoints.clear();
                              _userDestination = null;
                              _distanceKm = null;
                              _durationMin = null;
                            });
                            return;
                          }

                          if (!mounted) return;
                          setState(() {
                            _isSearching = true;
                            _loadingMessage =
                                'Searching location, please wait...';
                          });

                          await fetchCoordPoint(destination);

                          if (!mounted) return;
                          setState(() => _isSearching = false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            150,
                            29,
                            20,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                        ),
                        child: const Icon(Icons.search, color: Colors.white),
                      ),
                    ],
                  ),

                  // Suggestions dropdown
                  if (_searchSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _searchSuggestions[index];
                          final displayName = suggestion['display_name'];
                          return ListTile(
                            title: Text(displayName),
                            onTap: () {
                              _searchController.text = displayName;
                              FocusScope.of(context).unfocus();
                              if (!mounted) return;
                              setState(() => _searchSuggestions.clear());
                              fetchCoordPoint(displayName);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Route summary card
          if (_distanceKm != null && _durationMin != null)
            Positioned(
              bottom: 90,
              left: 20,
              right: 20,
              child: Card(
                color: Color.fromARGB(199, 5, 41, 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Distance: ${_distanceKm!.toStringAsFixed(2)} km\n'
                    'Estimated Time of Arrival: ${_durationMin!.toStringAsFixed(0)} mins',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ),

          // Loading overlay
          if (_isSearching)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _loadingMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        onPressed: () async {
          if (!mounted) return;
          setState(() {
            _isSearching = true;
            _loadingMessage = 'Getting your current location...';
          });

          await _getUserLocation();

          if (!mounted) return;
          setState(() => _isSearching = false);
        },
        backgroundColor: const Color.fromARGB(255, 5, 41, 5),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
