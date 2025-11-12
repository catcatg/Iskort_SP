import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
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
        title: const Text("Your Activity"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0A4423),
          indicatorColor: const Color(0xFF0A4423),
          tabs: const [Tab(text: "All"), Tab(text: "Comments")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAllTab(), _buildCommentsTab()],
      ),
    );
  }

  // --- All Notifications ad Comments
  Widget _buildAllTab() {
    final items = [
      {
        'avatar': Icons.store,
        'user': 'CoffeeHub',
        'message': 'replied to your comment.',
        'time': '2h',
        'comment': 'Thanks for your feedback!',
      },
      {
        'avatar': Icons.person,
        'user': 'John Doe',
        'message': 'liked your review.',
        'time': '1d',
        'comment': '',
      },
      {
        'avatar': Icons.notifications_active,
        'user': '',
        'message': 'New discount available near you!',
        'time': '2d',
        'comment': '',
      },
    ];
    return _buildFeedList(items);
  }

  // --- User’s Comment History ---
  Widget _buildCommentsTab() {
    final comments = [
      {
        'avatar': Icons.person,
        'user': 'You',
        'message': 'commented on CoffeeHub.',
        'time': '3d',
        'comment': 'Great coffee and friendly staff!',
      },
      {
        'avatar': Icons.person,
        'user': 'You',
        'message': 'commented on Joe’s Diner.',
        'time': '1w',
        'comment': 'Parking could be better.',
      },
    ];
    return _buildFeedList(comments);
  }

  // --- Reusable Feed List Builder ---
  Widget _buildFeedList(List<Map<String, Object>> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 20),
      itemBuilder: (context, index) {
        final item = items[index];
        final icon = item['avatar'] as IconData?;
        final user = item['user'] as String? ?? '';
        final message = item['message'] as String? ?? '';
        final time = item['time'] as String? ?? '';
        final comment = item['comment'] as String? ?? '';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green[100],
            child: Icon(icon ?? Icons.notifications, color: Colors.green[800]),
          ),
          title: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                if (user.isNotEmpty)
                  TextSpan(
                    text: "$user ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                TextSpan(text: message),
              ],
            ),
          ),
          subtitle:
              comment.isNotEmpty
                  ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "“$comment”",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                  : null,
          trailing: Text(
            time,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          onTap: () {
            // navigate to detailed view
          },
        );
      },
    );
  }
}
