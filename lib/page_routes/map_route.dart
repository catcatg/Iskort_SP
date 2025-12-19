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
import 'package:iskort/widgets/reusables.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iskort/page_routes/estab_pin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:iskort/page_routes/static_pins.dart';

/// ===================== CONSTANTS =====================
class AppConstants {
  static const double defaultZoom = 16;
  static const double locationZoom = 17;
  static const double arrivalThresholdMeters = 20;
}

class IloiloBounds {
  static const minLat = 10.5;
  static const maxLat = 11.7;
  static const minLon = 121.9;
  static const maxLon = 123.0;

  static bool contains(double lat, double lon) {
    return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
  }
}

/// ===================== MODEL =====================
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

  Map<String, dynamic> toMap() => {
    'name': name,
    'lat': coordinates.latitude,
    'lng': coordinates.longitude,
    'distanceKm': distanceKm,
    'durationMin': durationMin,
    'timestamp': timestamp.toIso8601String(),
  };
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

/// ===================== PAGE =====================
class MapRoutePage extends StatefulWidget {
  final String? initialLocation;
  final dynamic ownerId;
  const MapRoutePage({super.key, this.initialLocation, this.ownerId});

  @override
  State<MapRoutePage> createState() => _MapRoutePageState();
}

final cacheManager = CacheManager(
  Config(
    'tiles',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 500,
  ),
);

class PrefetchTileProvider extends TileProvider {
  final BaseCacheManager cacheManager;

  PrefetchTileProvider(this.cacheManager);

  @override
  ImageProvider getImage(TileCoordinates coords, TileLayer tileLayer) {
    // Replace {z}, {x}, {y} in the URL
    String url = tileLayer.urlTemplate!
        .replaceAll('{z}', coords.z.toString())
        .replaceAll('{x}', coords.x.toString())
        .replaceAll('{y}', coords.y.toString());

    // Replace {s} subdomain if provided
    if (tileLayer.subdomains != null && tileLayer.subdomains!.isNotEmpty) {
      final subdomain =
          tileLayer.subdomains![coords.x % tileLayer.subdomains!.length];
      url = url.replaceAll('{s}', subdomain);
    }

    // Use try/catch to fallback if caching fails
    try {
      return CachedNetworkImageProvider(url, cacheManager: cacheManager);
    } catch (e) {
      debugPrint('Tile load failed for $url: $e');
      return NetworkImage(url); // fallback to normal network image
    }
  }
}

class _MapRoutePageState extends State<MapRoutePage> {
  int? _ownerId;
  final MapController _mapController = MapController();
  final Location _locationService = Location();
  final TextEditingController _searchController = TextEditingController();
  final Distance _distanceCalc = const Distance();

  StreamSubscription<LocationData>? _locationSub;
  Timer? _debounce;

  LatLng? _userLocation;
  LatLng? _userDestination;
  List<LatLng> _routePoints = [];

  double? _distanceKm;
  double? _durationMin;

  bool _isLoading = false;
  bool _hasArrived = false;
  bool isSaved = false;

  List<Map<String, dynamic>> _searchSuggestions = [];
  String? _destinationName;
  List<Map<String, dynamic>> ownerPinsList = [];

  /// ===================== LIFECYCLE =====================
  @override
  void initState() {
    super.initState();
    _initLocation();
    _initLocationAndDestination();
    _loadOwnerPins();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('Owner ID from edit: ${widget.ownerId}');

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _ownerId = args['owner_id'];
    }
  }

  /// ===================== HELPERS =====================
  ///

  void _onOwnerLongPress(LatLng latlng) async {
    if (widget.ownerId == null) return;

    // Optional: limit pins to Iloilo bounds
    if (!IloiloBounds.contains(latlng.latitude, latlng.longitude)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pin must be inside Iloilo")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Add establishment pin here?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  "Lat: ${latlng.latitude.toStringAsFixed(6)}\n"
                  "Lng: ${latlng.longitude.toStringAsFixed(6)}",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A4423),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.location_on),
                  label: const Text("Add Pin"),
                  onPressed: () async {
                    Navigator.pop(context);

                    EstabPin(
                      ownerId: widget.ownerId!,
                      userLocation: latlng,
                      mapController: _mapController,
                      onPinAdded: (_) async {
                        await _loadOwnerPins();
                        if (mounted) setState(() {});
                      },
                    ).showAddPinSheet(context);
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadOwnerPins() async {
    final prefs = await SharedPreferences.getInstance();
    final pins = prefs.getStringList('owner_pins') ?? [];
    ownerPinsList =
        pins.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    // If in edit mode, place pin at owner's saved location
    if (widget.ownerId != null) {
      final ownerPin = ownerPinsList.firstWhere(
        (p) => p['ownerId'] == widget.ownerId,
        orElse: () => {},
      );

      if (ownerPin.isNotEmpty) {
        setState(() {
          _userDestination = LatLng(ownerPin['lat'], ownerPin['lng']);
          _destinationName = ownerPin['title'] ?? 'Owner Pin';
          _routePoints.clear(); // ensure polyline is not drawn
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(_userDestination!, AppConstants.defaultZoom);
        });
      }
    }

    setState(() {}); // refresh pins
  }

  Map<String, dynamic> evalStringMap(String str) {
    // crude way to parse stringified map, or store as JSON instead
    return jsonDecode(str.replaceAll("'", '"'));
  }

  Future<http.Response> _get(Uri url) {
    return http.get(
      url,
      headers: {"User-Agent": "IskortMap/1.0 (iskortmap@gmail.com)"},
    );
  }

  Future<void> _initLocationAndDestination() async {
    _showLoading();
    try {
      await _getUserLocation();

      if (widget.initialLocation != null &&
          widget.initialLocation!.isNotEmpty) {
        _searchController.text = widget.initialLocation!;
        await fetchCoordPoint(widget.initialLocation!);
      }
    } finally {
      _hideLoading();
    }
  }

  String _formatDuration(double minutes) {
    final m = minutes.toInt();
    if (m < 60) return '$m mins';
    final h = m ~/ 60;
    return '$h hr${h > 1 ? 's' : ''} ${m % 60} mins';
  }

  void _showPinCard(BuildContext context, Map pin) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pin['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(pin['address']),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  // set as destination and fetch route
                },
                child: const Text("Navigate"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLoading() {
    if (!mounted) return;
    setState(() => _isLoading = true);
  }

  void _hideLoading() {
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _clearSearchAndCard() {
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

  Future<void> _openSavedLocationsScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedLocations()),
    );

    if (result is LocationRecord) {
      setState(() {
        _userDestination = result.coordinates;
        _distanceKm = result.distanceKm;
        _durationMin = result.durationMin;
        _destinationName = result.name;
        isSaved = true;
        _hasArrived = false;
      });
      _mapController.move(_userDestination!, AppConstants.defaultZoom);
      await _fetchRoute();
    }
  }

  /// ===================== LOCATION =====================
  Future<void> _initLocation() async {
    if (!await _checkPermissions()) return;

    _locationSub = _locationService.onLocationChanged.listen((data) {
      if (data.latitude == null || data.longitude == null) return;

      setState(() {
        _userLocation = LatLng(data.latitude!, data.longitude!);
      });

      _checkArrival();
    });
  }

  Future<bool> _checkPermissions() async {
    if (kIsWeb) return true; // skip permissions on web

    if (!await _locationService.serviceEnabled() &&
        !await _locationService.requestService()) {
      return false;
    }

    var permission = await _locationService.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _locationService.requestPermission();
    }
    return permission == PermissionStatus.granted;
  }

  Future<void> _getUserLocation() async {
    final loc = await _locationService.getLocation();

    if (loc.latitude == null || loc.longitude == null) {
      throw Exception("Location unavailable");
    }

    final pos = LatLng(loc.latitude!, loc.longitude!);
    setState(() => _userLocation = pos);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(pos, AppConstants.locationZoom);
    });
  }

  /// ===================== SEARCH =====================
  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _searchSuggestions.clear());
      return;
    }

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=$query&format=json&limit=5'
      '&viewbox=${IloiloBounds.minLon},${IloiloBounds.minLat},'
      '${IloiloBounds.maxLon},${IloiloBounds.maxLat}&bounded=1',
    );

    final response = await _get(url);
    if (response.statusCode != 200) return;

    final data = json.decode(response.body) as List;
    setState(() {
      _searchSuggestions =
          data
              .where(
                (s) => IloiloBounds.contains(
                  double.parse(s['lat']),
                  double.parse(s['lon']),
                ),
              )
              .cast<Map<String, dynamic>>()
              .toList();
    });
  }

  /// ===================== ROUTING =====================
  Future<void> fetchNearestCoord(String query) async {
    if (query.isEmpty) return;
    await fetchCoordPoint(query);
  }

  Future<void> fetchCoordPoint(String location) async {
    _showLoading();

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=$location&format=json&limit=1'
        '&viewbox=${IloiloBounds.minLon},${IloiloBounds.minLat},'
        '${IloiloBounds.maxLon},${IloiloBounds.maxLat}&bounded=1',
      );

      final response = await _get(url);
      if (response.statusCode != 200) {
        await showTemporaryPopup(context, "Failed to fetch location.");
        return;
      }

      final data = json.decode(response.body);
      if (data.isEmpty) {
        await showTemporaryPopup(context, "Location not found in Iloilo.");
        return;
      }

      final lat = double.parse(data[0]['lat']);
      final lon = double.parse(data[0]['lon']);

      if (!IloiloBounds.contains(lat, lon)) {
        await showTemporaryPopup(context, "Location is outside Iloilo.");
        return;
      }

      setState(() {
        _userDestination = LatLng(lat, lon);
        _destinationName = data[0]['display_name'];
        _searchSuggestions.clear();
        _hasArrived = false;
      });

      _mapController.move(_userDestination!, AppConstants.defaultZoom);
      await _fetchRoute();
      await _checkIfLocationIsSaved();
    } catch (e) {
      await showTemporaryPopup(context, "Something went wrong.");
    } finally {
      _hideLoading();
    }
  }

  Future<void> _fetchRoute() async {
    if (_userLocation == null || _userDestination == null) return;

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${_userLocation!.longitude},${_userLocation!.latitude};'
      '${_userDestination!.longitude},${_userDestination!.latitude}'
      '?overview=full&geometries=polyline',
    );

    final response = await _get(url);
    if (response.statusCode != 200) return;

    final data = json.decode(response.body);
    final route = data['routes'][0];

    final points =
        PolylinePoints()
            .decodePolyline(route['geometry'])
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

    setState(() {
      _routePoints = points;
      _distanceKm = route['distance'] / 1000;
      _durationMin = route['duration'] / 60;
    });
  }

  /// ===================== SAVED =====================
  Future<void> _checkIfLocationIsSaved() async {
    if (_userDestination == null) return;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_locations') ?? [];

    setState(() {
      isSaved = saved.any((item) {
        final d = jsonDecode(item);
        return d['lat'] == _userDestination!.latitude &&
            d['lng'] == _userDestination!.longitude;
      });
    });
  }

  Future<void> _toggleSaveCurrentLocation() async {
    if (_userDestination == null || _distanceKm == null || _durationMin == null)
      return;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_locations') ?? [];

    if (isSaved) {
      saved.removeWhere((item) {
        final d = jsonDecode(item);
        return d['lat'] == _userDestination!.latitude &&
            d['lng'] == _userDestination!.longitude;
      });
    } else {
      final String finalName =
          _searchController.text.trim().isNotEmpty
              ? _searchController.text.trim()
              : (_destinationName?.trim().isNotEmpty == true
                  ? _destinationName!
                  : 'Pinned Location');

      final record = LocationRecord(
        name: finalName,
        coordinates: _userDestination!,
        distanceKm: _distanceKm!,
        durationMin: _durationMin!,
        timestamp: DateTime.now(),
      );

      saved.add(jsonEncode(record.toMap()));
    }

    await prefs.setStringList('saved_locations', saved);
    setState(() => isSaved = !isSaved);
  }

  /// ===================== ARRIVAL =====================
  void _checkArrival() {
    if (_userLocation == null || _userDestination == null) return;

    final meters = _distanceCalc(_userLocation!, _userDestination!);

    if (meters <= AppConstants.arrivalThresholdMeters && !_hasArrived) {
      setState(() {
        _hasArrived = true;
        _routePoints.clear();
        _distanceKm = null;
        _durationMin = null;
        _userDestination = null;
      });

      showDialog(
        context: context,
        builder:
            (_) => const AlertDialog(
              title: Text("Arrived"),
              content: Text("You have arrived at your destination."),
            ),
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
        title: Text(
          widget.ownerId != null ? "Pin your location" : "Iskort Map",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 150, 29, 20),
        actions: [
          if (widget.ownerId == null) ...[
            IconButton(
              icon: const Icon(Icons.book, color: Colors.white),
              onPressed: _openSavedLocationsScreen,
            ),
          ],
        ],
      ),

      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? const LatLng(11.0, 122.5),
              initialZoom: 16,
              minZoom: 1,
              maxZoom: 100,

              // 👇 OWNER LONG PRESS
              onLongPress: (tapPosition, latlng) {
                if (widget.ownerId != null) {
                  _onOwnerLongPress(latlng);
                }
              },
            ),

            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
                tileProvider: PrefetchTileProvider(cacheManager),
              ),

              CurrentLocationLayer(
                //alignPositionOnUpdate: AlignOnUpdate.always,
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
              if (ownerPinsList.isNotEmpty)
                ...ownerPinsList.map((pin) {
                  final bool isOwner =
                      widget.ownerId != null &&
                      pin['ownerId'] == widget.ownerId;

                  final dragMarker = DragMarker(
                    point: LatLng(pin['lat'], pin['lng']),
                    size: const Size(40, 40),
                    builder: (ctx, mapState, draggable) {
                      return GestureDetector(
                        onTap: () {
                          EstabPin.showPinDetailsSheet(
                            context: context,
                            pin: pin,
                            currentOwnerId: widget.ownerId,
                            onPinUpdated: (_) => setState(() {}),
                            reloadPins: _loadOwnerPins,
                            navigateToPin: (coords) async {
                              setState(() {
                                _userDestination = coords;
                                _destinationName = pin['title'];
                                _searchController.text = pin['title'];
                                _hasArrived = false;
                              });

                              _mapController.move(
                                coords,
                                AppConstants.defaultZoom,
                              );
                              await _fetchRoute();
                            },
                          );
                        },
                        child: Icon(
                          Icons.location_on,
                          size: 40,
                          color: isOwner ? Colors.blue : Color(0xFF7A1E1E),
                        ),
                      );
                    },
                    disableDrag: !isOwner,
                    onDragEnd: (details, newPosition) async {
                      if (!isOwner) return;

                      setState(() {
                        pin['lat'] = newPosition.latitude;
                        pin['lng'] = newPosition.longitude;
                      });

                      await EstabPin.updatePin(
                        oldPin: pin,
                        newTitle: pin['title'],
                        newAddress: pin['address'],
                        newCoords: newPosition,
                      );
                    },
                  );

                  // Wrap DragMarkerWidget in Builder to safely access MapCamera
                  return Builder(
                    builder: (context) {
                      final mapCamera = MapCamera.of(context);
                      return DragMarkerWidget(
                        marker: dragMarker,
                        mapController: _mapController,
                        mapCamera: mapCamera, // required parameter
                      );
                    },
                  );
                }),

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
              MarkerLayer(
                markers:
                    staticPins.map((pin) {
                      return Marker(
                        point: pin.location,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () {
                            EstabPin.showPinDetailsSheet(
                              context: context,
                              pin: {
                                'title': pin.title,
                                'address': pin.address,
                                'lat': pin.location.latitude,
                                'lng': pin.location.longitude,
                                'ownerId': null,
                                'type': pin.type,
                              },
                              currentOwnerId: widget.ownerId,
                              onPinUpdated: (_) {},
                              reloadPins: () async {},
                              navigateToPin: (coords) async {
                                setState(() {
                                  _userDestination = coords;
                                  _destinationName = pin.title;
                                  _searchController.text =
                                      pin.title; // ⭐ IMPORTANT
                                });

                                _mapController.move(
                                  coords,
                                  AppConstants.defaultZoom,
                                );
                                await _fetchRoute();
                              },
                            );
                          },
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFF7A1E1E),
                            size: 40,
                          ),
                        ),
                      );
                    }).toList(),
              ),

              if (widget.ownerId == null &&
                  _userLocation != null &&
                  _routePoints.isNotEmpty)
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
                        if (widget.ownerId == null) ...[
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
                                      'ETA: ${_formatDuration(_durationMin!)}',
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
                        ],

                        const SizedBox(height: 12),

                        // Save location button
                        if (widget.ownerId == null) ...[
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
                    fetchNearestCoord(value);
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
                          fetchNearestCoord(query);
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
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text("Loading...", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 15),
          FloatingActionButton(
            heroTag: 'my_location',
            backgroundColor: const Color.fromARGB(255, 150, 29, 20),
            onPressed: _getUserLocation,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
