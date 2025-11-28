import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditEstablishmentsPage extends StatefulWidget {
  final int ownerId;
  const EditEstablishmentsPage({super.key, required this.ownerId});

  @override
  State<EditEstablishmentsPage> createState() => _EditEstablishmentsPageState();
}

class _EditEstablishmentsPageState extends State<EditEstablishmentsPage> {
  List<dynamic> eateries = [];
  List<dynamic> housings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEstablishments();
  }

  Future<void> fetchEstablishments() async {
    try {
      final eateryResp = await http.get(
        Uri.parse('https://iskort-public-web.onrender.com/api/eatery'),
      );
      final housingResp = await http.get(
        Uri.parse('https://iskort-public-web.onrender.com/api/housing'),
      );

      final eateryData = jsonDecode(eateryResp.body);
      final housingData = jsonDecode(housingResp.body);

      setState(() {
        eateries = (eateryData['eateries'] ?? [])
            .where((e) => e['owner_id'] == widget.ownerId)
            .toList();
        housings = (housingData['housings'] ?? [])
            .where((h) => h['owner_id'] == widget.ownerId)
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching establishments: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Establishments")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text("Eateries", style: TextStyle(fontWeight: FontWeight.bold)),
                ...eateries.map((e) => ListTile(
                      title: Text(e['name']),
                      subtitle: Text(e['location']),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/edit-eatery',
                            arguments: e,
                          );
                        },
                      ),
                    )),
                const SizedBox(height: 20),
                const Text("Housings", style: TextStyle(fontWeight: FontWeight.bold)),
                ...housings.map((h) => ListTile(
                      title: Text(h['name']),
                      subtitle: Text(h['location']),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/edit-housing',
                            arguments: h,
                          );
                        },
                      ),
                    )),
              ],
            ),
    );
  }
}