import 'package:flutter/material.dart';
import 'view_estab_profile.dart';

class YourReviews extends StatefulWidget {
  const YourReviews({super.key});

  @override
  State<YourReviews> createState() => _YourReviewsState();
}

class _YourReviewsState extends State<YourReviews>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReviewsTab(allReviews: true),
          _buildReviewsTab(allReviews: false),
        ],
      ),
    );
  }

  Widget _buildReviewsTab({required bool allReviews}) {
    // Use the singleton storage for user reviews
    final reviews =
        allReviews
            ? UserReviewsStorage.instance.reviews
            : UserReviewsStorage.instance.reviews.reversed.take(1).toList();

    if (reviews.isEmpty) {
      return const Center(child: Text("No reviews yet"));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const Divider(height: 20),
      itemBuilder: (context, index) {
        final r = reviews[index];
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
                      "You reviewed ${r['shopName']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        rating,
                        (_) => const Icon(
                          Icons.local_florist,
                          size: 16,
                          color: Color(0xFFFBAC24),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  r['review'] ?? r['comment'] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  r['date'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
