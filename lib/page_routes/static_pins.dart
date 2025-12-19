import 'package:latlong2/latlong.dart';

class StaticPin {
  final String id;
  final String title;
  final String address;
  final LatLng location;
  final String type;

  const StaticPin({
    required this.id,
    required this.title,
    required this.address,
    required this.location,
    required this.type,
  });
}

const List<StaticPin> staticPins = [
  StaticPin(
    id: 'municipal_hall',
    title: 'Miagao Municipal Hall',
    address: 'Miagao, Iloilo City',
    location: LatLng(10.640754, 122.235059),
    type: 'landmark',
  ),
  StaticPin(
    id: 'public_market',
    title: 'Miagao Public Market',
    address: 'Miagao, Iloilo',
    location: LatLng(10.640424, 122.238538),
    type: 'market',
  ),
  StaticPin(
    id: 'wet_market',
    title: 'Miagao Wet Market',
    address: 'Miagao, Iloilo',
    location: LatLng(10.640761, 122.237363),
    type: 'market',
  ),
  StaticPin(
    id: 'miagao_church',
    title: 'Miagao Church',
    address: 'Miag-ao Church, Miagao, Iloilo',
    location: LatLng(10.641866, 122.235410),
    type: 'church',
  ),
  StaticPin(
    id: 'hello_burger',
    title: 'Hello Burger',
    address: 'Miagao, Iloilo',
    location: LatLng(10.643631, 122.234901),
    type: 'restaurant',
  ),
  StaticPin(
    id: 'piging',
    title: 'Piging Restaurant',
    address: 'Bolho, Sapa, Miagao, Iloilo',
    location: LatLng(10.640561, 122.231827),
    type: 'restaurant',
  ),
  StaticPin(
    id: 'vnyrd',
    title: 'Vineyard',
    address: 'Mueda, Bolho, Miagao, Iloilo',
    location: LatLng(10.639216, 122.236378),
    type: 'restaurant',
  ),
  StaticPin(
    id: 'nismals',
    title: 'Pizza Flavors Cuisine',
    address: 'Octaviano, baybay Norte, Miagao, Iloilo',
    location: LatLng(10.639849, 122.237384),
    type: 'restaurant',
  ),
  StaticPin(
    id: 'kfeels',
    title: 'K-feels',
    address: 'Bolho, Sapa, Miagao, Iloilo',
    location: LatLng(10.640470, 122.231897),
    type: 'restaurant',
  ),
  StaticPin(
    id: 'hsu',
    title: 'UPV HSU',
    address: 'Mat-y, Miagao, Iloilo',
    location: LatLng(10.645788, 122.230169),
    type: 'infirmary',
  ),
  StaticPin(
    id: 'cub',
    title: 'UPV CUB',
    address: 'UPVEC Consumer Cooperative, Miagao, Iloilo',
    location: LatLng(10.640185, 122.228418),
    type: 'building',
  ),
  StaticPin(
    id: 'bowla',
    title: 'UPV Bowling Alley Building',
    address: 'Miagao, Iloilo',
    location: LatLng(10.640127, 122.228107),
    type: 'building',
  ),
  StaticPin(
    id: 'cas',
    title: 'UPV CAS',
    address: 'UPV College of Arts and Sciences, Miagao, Iloilo',
    location: LatLng(10.640861, 122.227575),
    type: 'building',
  ),
  StaticPin(
    id: 'casp',
    title: 'UPV CAS Park',
    address: 'UPV College of Arts and Sciences, Miagao, Iloilo',
    location: LatLng(10.641066, 122.227806),
    type: 'park',
  ),
  StaticPin(
    id: 'cfos',
    title: 'UPV CFOS AV Hall',
    address: 'UPV College of Fisheries and Ocean Sciences, Miagao, Iloilo',
    location: LatLng(10.639406, 122.229939),
    type: 'park',
  ),
];
