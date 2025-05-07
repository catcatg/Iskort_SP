// API KEY '5b3ce3597851110001cf6248a6f3b67e3a8c448a91fa92c0fa878fbd';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class Suggestion {
  final String label;
  final double lat;
  final double lon;

  Suggestion({required this.label, required this.lat, required this.lon});
}

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentLocation;
  LatLng? _searchedLocation;

  final String _apiKey =
      '5b3ce3597851110001cf6248a6f3b67e3a8c448a91fa92c0fa878fbd';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied.'),
        ),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    _mapController.move(_currentLocation!, 15.0);
  }

  Future<List<Suggestion>> _getSuggestions(String input) async {
    final url = Uri.parse(
      'https://api.openrouteservice.org/geocode/autocomplete',
    );

    final response = await http.get(
      url.replace(
        queryParameters: {
          'api_key': _apiKey,
          'text': input,
          'size': '5',
          'boundary.country': 'PH', // limited to Philippines
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Suggestion> suggestions = [];

      for (var feature in data['features']) {
        suggestions.add(
          Suggestion(
            label: feature['properties']['label'],
            lat: feature['geometry']['coordinates'][1],
            lon: feature['geometry']['coordinates'][0],
          ),
        );
      }

      return suggestions;
    } else {
      print('Failed to fetch suggestions: ${response.statusCode}');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Iskort Route Finder")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Autocomplete<Suggestion>(
                    displayStringForOption: (Suggestion option) => option.label,
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Suggestion>.empty();
                      }
                      return await _getSuggestions(textEditingValue.text);
                    },
                    onSelected: (Suggestion selectedSuggestion) {
                      _searchController.text = selectedSuggestion.label;
                      setState(() {
                        _searchedLocation = LatLng(
                          selectedSuggestion.lat,
                          selectedSuggestion.lon,
                        );
                      });
                      _mapController.move(_searchedLocation!, 15.0);
                    },
                    fieldViewBuilder: (
                      context,
                      controller,
                      focusNode,
                      onEditingComplete,
                    ) {
                      _searchController.value = controller.value;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: const InputDecoration(
                          hintText: "Enter destination",
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(
                  14.5995,
                  120.9842,
                ), // Manila default (fallback)
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                if (_searchedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _searchedLocation!,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                if (_currentLocation != null && _searchedLocation != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_currentLocation!, _searchedLocation!],
                        color: Colors.green,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
