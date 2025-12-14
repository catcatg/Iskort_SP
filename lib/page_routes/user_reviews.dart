import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class YourReviews extends StatefulWidget {
  const YourReviews({super.key});

  @override
  State<YourReviews> createState() => _YourReviewsState();
}

class _YourReviewsState extends State<YourReviews>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;

  final String baseUrl = 'https://iskort-public-web.onrender.com';
  final int userId = 1; // TODO: replace with logged-in user_id

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/user/$userId/reviews'));
      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        setState(() {
          reviews = List<Map<String, dynamic>>.from(data['reviews'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('fetchReviews error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> editReview(int reviewId, String type, int rating, String comment) async {
    final endpoint = type == 'eatery'
        ? '$baseUrl/api/eatery_reviews/$reviewId'
        : '$baseUrl/api/housing_reviews/$reviewId';

    try {
      final res = await http.put(
        Uri.parse(endpoint),
        body: {'rating': rating.toString(), 'comment': comment},
      );
      final data = jsonDecode(res.body);
      print('Edit response: $data');
      fetchReviews();
    } catch (e) {
      print('editReview error: $e');
    }
  }

  Future<void> deleteReview(int reviewId, String type) async {
    final endpoint = type == 'eatery'
        ? '$baseUrl/api/eatery_reviews/$reviewId'
        : '$baseUrl/api/housing_reviews/$reviewId';

    try {
      final res = await http.delete(Uri.parse(endpoint));
      final data = jsonDecode(res.body);
      print('Delete response: $data');
      fetchReviews();
    } catch (e) {
      print('deleteReview error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text("Your Reviews"),
        backgroundColor: const Color.fromARGB(255, 150, 29, 20),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0A4423),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF0A4423),
              tabs: const [Tab(text: "All Reviews"), Tab(text: "Recent")],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReviewsTab(allReviews: true),
                _buildReviewsTab(allReviews: false),
              ],
            ),
    );
  }

  Widget _buildReviewsTab({required bool allReviews}) {
    final list = allReviews ? reviews : reviews.take(5).toList();

    if (list.isEmpty) {
      return const Center(child: Text("No reviews yet"));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 20),
      itemBuilder: (context, index) {
        final r = list[index];
        final rating = r['rating'] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "You reviewed ${r['place_name']} (${r['type']})",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        rating,
                        (_) => const Icon(
                          Icons.local_florist, // 🌻 sunflower substitute
                          size: 16,
                          color: Color(0xFFFBAC24),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(r['comment'] ?? '', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  r['created_at'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        // Example: open dialog to edit
                        editReview(r['review_id'], r['type'], rating, r['comment'] ?? '');
                      },
                      child: const Text("Edit"),
                    ),
                    TextButton(
                      onPressed: () => deleteReview(r['review_id'], r['type']),
                      child: const Text("Delete", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}