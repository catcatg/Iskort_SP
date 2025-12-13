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
import 'package:iskort/page_routes/saved_locations.dart';

class LocationRecord {
  final String name;
  final LatLng coordinates;
  final double distanceKm;
  final double durationMin;
  final DateTime timestamp;

  LocationRecord({
    required this.name,
    required this.coordinates,
    required this.distanceKm,
    required this.durationMin,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lat': coordinates.latitude,
      'lng': coordinates.longitude,
      'distanceKm': distanceKm,
      'durationMin': durationMin,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationRecord.fromMap(Map<String, dynamic> map) {
    return LocationRecord(
      name: map['name'],
      coordinates: LatLng(map['lat'], map['lng']),
      distanceKm: map['distanceKm'],
      durationMin: map['durationMin'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

class MapRoutePage extends StatefulWidget {
  final String? initialLocation;

  const MapRoutePage({super.key, this.initialLocation});

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
  bool _hasArrived = false;

  // Saved locations
  List<LocationRecord> savedLocations = [];
  bool isSaved = false;
  String? _destinationName;

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
    //_loadLastDestination();
    _searchController.clear();

    // If initialLocation is provided, auto fill search bar and fetch
    if (widget.initialLocation != null && widget.initialLocation!.isNotEmpty) {
      _searchController.text = widget.initialLocation!;
      fetchCoordPoint(widget.initialLocation!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _openSavedLocationsScreen() async {
    // Clear the card and search when navigating to other pages
    if (!mounted) return;
    setState(() {
      _searchController.clear();
      _routePoints.clear();
      _userDestination = null;
      _distanceKm = null;
      _durationMin = null;
      _searchSuggestions.clear();
      _destinationName = null;
      isSaved = false;
    });

    final selectedRecord = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SavedLocations()),
    );

    if (selectedRecord != null && selectedRecord is LocationRecord) {
      setState(() {
        _searchController.clear();
        _userDestination = selectedRecord.coordinates;
        _distanceKm = selectedRecord.distanceKm;
        _durationMin = selectedRecord.durationMin;
        _destinationName = selectedRecord.name;
        isSaved = true;
        _hasArrived = false;
      });

      _mapController.move(_userDestination!, 18);
      await _fetchRoute();
    }
  }

  Future<void> _toggleSaveCurrentLocation() async {
    if (_userDestination == null || _distanceKm == null || _durationMin == null)
      return;

    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('saved_locations') ?? [];

    final record = LocationRecord(
      name:
          _searchController.text.trim().isEmpty
              ? 'Unnamed Location'
              : _searchController.text.trim(),
      coordinates: _userDestination!,
      distanceKm: _distanceKm!,
      durationMin: _durationMin!,
      timestamp: DateTime.now(),
    );

    final recordMap = jsonEncode(record.toMap());

    if (isSaved) {
      savedList.remove(recordMap);
    } else {
      savedList.add(recordMap);
    }

    await prefs.setStringList('saved_locations', savedList);

    if (!mounted) return;
    setState(() {
      isSaved = !isSaved;
    });
  }

  // Future<void> _loadLastDestination() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final last = prefs.getString('last_destination');
  //   if (last != null && mounted) {
  //     _searchController.text = last;
  //     await fetchCoordPoint(last, moveCamera: false);
  //   }
  // }

  Future<void> _saveLastDestination(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_destination', location);
  }

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

        _checkArrival(); // Check if arrived
      }
    });
  }

  Future<void> fetchCoordPoint(
    String location, {
    bool moveCamera = true,
  }) async {
    try {
      // Bounding box for entire Iloilo province
      const double minLat = 10.5;
      const double maxLat = 11.7;
      const double minLon = 121.9;
      const double maxLon = 123.0;

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=$location'
        '&format=json'
        '&limit=1'
        '&viewbox=$minLon,$minLat,$maxLon,$maxLat'
        '&bounded=1',
      );

      final response = await http.get(
        url,
        headers: {"User-Agent": "IskortMap/1.0 (iskortmap@gmail.com)"},
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);

          // Extra safety check
          if (lat < minLat || lat > maxLat || lon < minLon || lon > maxLon) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location is outside Iloilo province.'),
              ),
            );
            return;
          }

          if (!mounted) return;
          setState(() {
            _userDestination = LatLng(lat, lon);
            _searchSuggestions.clear();
            _hasArrived = false;
          });

          if (moveCamera) _mapController.move(_userDestination!, 18);

          await _fetchRoute();
          _saveLastDestination(location);
          await _checkIfLocationIsSaved();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location not found in Iloilo province.'),
            ),
          );
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

  Future<void> _checkIfLocationIsSaved() async {
    if (_userDestination == null) return;

    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList('saved_locations') ?? [];

    final isAlreadySaved = savedList.any((item) {
      final data = jsonDecode(item);
      final savedLat = data['lat'];
      final savedLng = data['lng'];
      return savedLat == _userDestination!.latitude &&
          savedLng == _userDestination!.longitude;
    });

    if (!mounted) return;
    setState(() {
      isSaved = isAlreadySaved;
    });
  }

  Future<void> _fetchRoute() async {
    if (_userLocation == null || _userDestination == null) return;

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/${_userLocation!.longitude},${_userLocation!.latitude};${_userDestination!.longitude},${_userDestination!.latitude}?overview=full&geometries=polyline',
    );
    final response = await http.get(
      url,
      headers: {"User-Agent": "IskortMap/1.0 (iskortmap@gmail.com)"},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final geometry = data['routes'][0]['geometry'];
      final distance = data['routes'][0]['distance'] / 1000;
      final duration = data['routes'][0]['duration'] / 60;
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

  void _clearSearchAndCard() {
    if (!mounted) return;
    setState(() {
      _searchController.clear();
      _routePoints.clear();
      _userDestination = null;
      _distanceKm = null;
      _durationMin = null;
      _searchSuggestions.clear();
      _destinationName = null;
      isSaved = false;
      _hasArrived = false;
    });
  }

  void _checkArrival() {
    if (_userLocation == null || _userDestination == null) return;

    final distance = Distance();
    final meterDistance = distance(_userLocation!, _userDestination!);

    if (meterDistance <= 20 && !_hasArrived) {
      // 20 meters threshold
      if (!mounted) return;
      setState(() {
        _hasArrived = true;
        _routePoints.clear();
        _distanceKm = null;
        _durationMin = null;
        _userDestination = null;
      });

      // Show arrival dialog
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0A4423), // dark green
                    Color(0xFF7A1E1E), // deep red
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Icon(Icons.location_on, color: Colors.white, size: 60),
                  const SizedBox(height: 10),
                  const Text(
                    "You have arrived at your destination!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

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
        _mapController.move(pos, 19);
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

    // Bounding box for entire Iloilo province
    const double minLat = 10.5;
    const double maxLat = 11.7;
    const double minLon = 121.9;
    const double maxLon = 123.0;

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=$query'
      '&format=json'
      '&limit=5'
      '&addressdetails=1'
      '&viewbox=$minLon,$minLat,$maxLon,$maxLat'
      '&bounded=1',
    );

    final response = await http.get(
      url,
      headers: {"User-Agent": "IskortMap/1.0 (iskortmap@gmail.com)"},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (!mounted) return;

      // Extra safety filter
      final filtered =
          (data as List).where((s) {
            final lat = double.parse(s['lat']);
            final lon = double.parse(s['lon']);
            return lat >= minLat &&
                lat <= maxLat &&
                lon >= minLon &&
                lon <= maxLon;
          }).toList();

      setState(
        () => _searchSuggestions = List<Map<String, dynamic>>.from(filtered),
      );
    }
  }

  // ====================== UI ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _clearSearchAndCard();
            Navigator.pop(context);
          },
        ),

        foregroundColor: Colors.white,
        title: const Text("Iskort Map"),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: const Color.fromARGB(255, 150, 29, 20),
        actions: [
          IconButton(
            icon: const Icon(Icons.book, color: Colors.white),
            onPressed: _openSavedLocationsScreen,
          ),
        ],
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
                style: LocationMarkerStyle(
                  markerSize: Size(40, 40), // size of the whole marker
                  markerDirection: MarkerDirection.heading,
                  marker: DefaultLocationMarker(
                    child: Center(
                      child: Container(
                        width: 40, // circle width
                        height: 40, // circle height
                        decoration: BoxDecoration(
                          color: Color(0xFFFBAC24),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.navigation,
                            color: Colors.white,
                            size: 24, // size of the icon itself
                          ),
                        ),
                      ),
                    ),
                  ),
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

          if (_distanceKm != null && _durationMin != null)
            Positioned(
              bottom: 90,
              left: 20,
              right: 20,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0A4423), // dark green
                        Color(0xFF7A1E1E), // deep red
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Close button
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white70,
                            ),
                            onPressed: _clearSearchAndCard,
                          ),
                        ),

                        // Location name
                        if (_searchController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              _searchController.text,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else if (_destinationName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              _destinationName!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // ETA and Distance
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                    180,
                                    255,
                                    255,
                                    255,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'ETA: ${_durationMin!.toStringAsFixed(0)} mins',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(left: 6),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                    180,
                                    255,
                                    255,
                                    255,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Distance: ${_distanceKm!.toStringAsFixed(2)} km',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Save location button
                        ElevatedButton.icon(
                          onPressed: _toggleSaveCurrentLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFBAC24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                          label: Text(
                            isSaved ? "Saved" : "Save Location",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Search bar and suggestions
          // ====================== Search bar ======================
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      _fetchSuggestions(value); // your autocomplete suggestions
                    });
                  },
                  onSubmitted: (value) {
                    fetchCoordPoint(
                      value,
                    ); // fetch route when user presses enter
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Search destination",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Color(0xFF0A4423),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Color(0xFF0A4423),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Color(0xFF0A4423),
                        width: 2,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search, color: Color(0xFF0A4423)),
                      onPressed: () {
                        final query = _searchController.text;
                        if (query.isNotEmpty) {
                          fetchCoordPoint(query);
                        }
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),

                if (_searchSuggestions.isNotEmpty)
                  Container(
                    color: Colors.white,
                    child: Column(
                      children:
                          _searchSuggestions.map((s) {
                            return ListTile(
                              title: Text(s['display_name']),
                              onTap: () {
                                _searchController.text = s['display_name'];
                                fetchCoordPoint(s['display_name']);
                                setState(() => _searchSuggestions.clear());
                              },
                            );
                          }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 150, 29, 20),
        onPressed: _getUserLocation,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
