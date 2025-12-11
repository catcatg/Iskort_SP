// CLEAN + OPTIMIZED ADMIN DASHBOARD
// Uses backend JOIN results (owner_name, owner_email, owner_phone)
// Single-file admin dashboard with Users / Eateries / Housings
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iskort/widgets/format_date.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int selectedPage = 0; // 0=Dashboard,1=Users,2=Eatery,3=Housing
  final String baseUrl = 'https://iskort-public-web.onrender.com';

  // Data states
  List users = [], eateries = [], housings = [];
  bool isLoadingUsers = true,
      isLoadingEateries = true,
      isLoadingHousings = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchEateries();
    fetchHousings();
  }

  // -------------------- FETCH FUNCTIONS --------------------
  Future<void> fetchUsers() async {
    setState(() => isLoadingUsers = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/admin/users'));
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          users = List<Map<String, dynamic>>.from(data['users'] ?? []);
          isLoadingUsers = false;
        });
      } else {
        setState(() => isLoadingUsers = false);
      }
    } catch (e) {
      print('fetchUsers error: $e');
      setState(() => isLoadingUsers = false);
    }
  }

  Future<void> fetchEateries() async {
    setState(() => isLoadingEateries = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/eatery'));
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          eateries = List<Map<String, dynamic>>.from(data['eateries'] ?? []);
          isLoadingEateries = false;
        });
      } else {
        setState(() => isLoadingEateries = false);
      }
    } catch (e) {
      print('fetchEateries error: $e');
      setState(() => isLoadingEateries = false);
    }
  }

  Future<void> fetchHousings() async {
    setState(() => isLoadingHousings = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/housing'));
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          housings = List<Map<String, dynamic>>.from(data['housings'] ?? []);
          isLoadingHousings = false;
        });
      } else {
        setState(() => isLoadingHousings = false);
      }
    } catch (e) {
      print('fetchHousings error: $e');
      setState(() => isLoadingHousings = false);
    }
  }

  // -------------------- ACTION FUNCTIONS --------------------
  Future<void> performUserAction(String id, String action) async {
    try {
      if (action == 'verify') {
        await http.put(Uri.parse('$baseUrl/api/admin/verify/$id'));
      } else {
        await http.delete(Uri.parse('$baseUrl/api/admin/reject/$id'));
      }
      fetchUsers();
    } catch (e) {
      print('performUserAction error: $e');
    }
  }

  Future<void> performEateryAction(String id, String action) async {
    try {
      if (action == 'verify') {
        await http.put(Uri.parse('$baseUrl/api/admin/verify/eatery/$id'));
      } else {
        await http.delete(Uri.parse('$baseUrl/api/admin/reject/eatery/$id'));
      }
      fetchEateries();
    } catch (e) {
      print('performEateryAction error: $e');
    }
  }

  Future<void> performHousingAction(String id, String action) async {
    try {
      if (action == 'verify') {
        await http.put(Uri.parse('$baseUrl/api/admin/verify/housing/$id'));
      } else {
        await http.delete(Uri.parse('$baseUrl/api/admin/reject/housing/$id'));
      }
      fetchHousings();
    } catch (e) {
      print('performHousingAction error: $e');
    }
  }

  Future<void> showRejectReasonDialog(String id, String type) async {
    String? selectedReason;
    final reasons = [
      'Invalid ID',
      'Incomplete Documents',
      'Incorrect Information',
      'Other',
    ];

    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Select Reject Reason'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  reasons
                      .map(
                        (r) => RadioListTile<String>(
                          title: Text(r),
                          value: r,
                          groupValue: selectedReason,
                          onChanged: (value) {
                            setState(() => selectedReason = value);
                            Navigator.pop(context);
                            performRejectWithReason(id, type, value!);
                          },
                        ),
                      )
                      .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> showApproveConfirmDialog(
    String id,
    String type,
    Function(String, String) performAction,
  ) async {
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Approve Application'),
            content: const Text(
              'Are you sure you want to approve this application?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  performAction(id, 'verify');
                },
                child: const Text(
                  'Approve',
                  style: TextStyle(color: Color(0xFF0A4423)),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> performRejectWithReason(
    String id,
    String type,
    String reason,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/api/admin/reject/$type/$id');
      await http.post(url, body: {'reason': reason});
      if (type == 'eatery') fetchEateries();
      if (type == 'housing') fetchHousings();
    } catch (e) {
      print('Reject with reason error: $e');
    }
  }

  // -------------------- DASHBOARD CARD --------------------
  Widget buildDashboardCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    double titleFont = screenWidth < 350 ? 14 : 16;
    double countFont = screenWidth < 350 ? 16 : 18;
    double iconSize = screenWidth < 350 ? 28 : 35;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFont,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0A4423),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: countFont,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- SIDEBAR --------------------
  Widget buildSidebarItem(String title, IconData icon, int index) {
    final isActive = selectedPage == index;

    return InkWell(
      onTap: () => setState(() => selectedPage = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF5E7E8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF0A4423) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              color: isActive ? const Color(0xFF0A4423) : Colors.black54,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? const Color(0xFF0A4423) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- PAGE CONTENT --------------------
  Widget buildPageContent() {
    switch (selectedPage) {
      case 0:
        return buildAdminDashboard();
      case 1:
        return UserManagementPage(
          users: users,
          isLoading: isLoadingUsers,
          onAction: performUserAction,
        );
      case 2:
        return EateryPage(
          eateries: eateries,
          isLoading: isLoadingEateries,
          onAction: performEateryAction,
          onRejectWithReason: showRejectReasonDialog,
          onApproveConfirm: (id, type) async {
            await showApproveConfirmDialog(id, type, performEateryAction);
          },
        );
      case 3:
        return HousingApplication(
          housings: housings,
          isLoading: isLoadingHousings,
          onAction: performHousingAction,
          onRejectWithReason: showRejectReasonDialog,
          onApproveConfirm: (id, type) async {
            await showApproveConfirmDialog(id, type, performHousingAction);
          },
        );
      default:
        return const Center(child: Text('Invalid Page'));
    }
  }

  // -------------------- ADMIN DASHBOARD --------------------
  Widget buildAdminDashboard() {
    final unverifiedUsersCount =
        users.where((u) => (u['is_verified'] ?? 0) != 1).length;

    // Determine crossAxisCount based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView(
        shrinkWrap: true,
        physics:
            NeverScrollableScrollPhysics(), // optional if you embed inside ScrollView
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.5,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        children: [
          buildDashboardCard(
            'Total Users',
            users.length,
            Icons.people,
            Colors.blue,
          ),
          buildDashboardCard(
            'Unverified Users',
            unverifiedUsersCount,
            Icons.person_off,
            Color.fromARGB(255, 182, 28, 33),
          ),
          buildDashboardCard(
            'Eateries',
            eateries.length,
            Icons.restaurant,
            Colors.orange,
          ),
          buildDashboardCard(
            'Housings',
            housings.length,
            Icons.hotel,
            Color.fromARGB(255, 21, 112, 60),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 230,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A4423),
                  ),
                ),
                Divider(color: Colors.grey.shade400),
                const SizedBox(height: 30),
                buildSidebarItem('Admin Dashboard', Icons.dashboard, 0),
                const SizedBox(height: 10),
                buildSidebarItem('Users Verification', Icons.people, 1),
                const SizedBox(height: 10),
                buildSidebarItem('Eatery Verification', Icons.restaurant, 2),
                const SizedBox(height: 10),
                buildSidebarItem('Housing Verification', Icons.hotel, 3),
                const Spacer(),
                const Divider(thickness: 2, color: Colors.grey),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/profile'),
                    icon: const Icon(Icons.home, color: Colors.white),
                    label: const Text(
                      'View Admin Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF0A4423),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0A4423), Color(0xFF7A1E1E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    selectedPage == 0
                        ? 'Admin Dashboard'
                        : selectedPage == 1
                        ? 'User Management'
                        : selectedPage == 2
                        ? 'Eatery Verification'
                        : 'Housing Verification',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: buildPageContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- USERS --------------------
class UserManagementPage extends StatelessWidget {
  final List users;
  final bool isLoading;
  final Function(String, String) onAction;

  const UserManagementPage({
    super.key,
    required this.users,
    required this.isLoading,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (users.isEmpty) return const Center(child: Text('No users found'));

    final Map<String, Map<String, dynamic>> uniqueUsersMap = {};
    for (var u in users) {
      final email = u['email'] ?? u['id'].toString();
      final existing = uniqueUsersMap[email];
      if (existing == null) {
        uniqueUsersMap[email] = Map<String, dynamic>.from(u);
      } else {
        DateTime existingDate =
            DateTime.tryParse(existing['created_at'] ?? '') ?? DateTime(2000);
        DateTime currentDate =
            DateTime.tryParse(u['created_at'] ?? '') ?? DateTime(2000);
        if (currentDate.isAfter(existingDate))
          uniqueUsersMap[email] = Map<String, dynamic>.from(u);
      }
    }

    final uniqueUsers = uniqueUsersMap.values.toList();
    final verifiedUsers =
        uniqueUsers.where((u) => (u['is_verified'] ?? 0) == 1).toList();
    final unverifiedUsers =
        uniqueUsers.where((u) => (u['is_verified'] ?? 0) == 0).toList();
    final rejectedUsers =
        uniqueUsers.where((u) => (u['is_verified'] ?? 0) == -1).toList();

    int sortByDate(Map a, Map b) {
      DateTime dateA =
          DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
      DateTime dateB =
          DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    }

    verifiedUsers.sort(sortByDate);
    unverifiedUsers.sort(sortByDate);
    rejectedUsers.sort(sortByDate);

    Widget buildUserList(List<Map<String, dynamic>> list) {
      if (list.isEmpty)
        return const Center(child: Text('No users in this category'));
      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final u = list[index];
          final verified = (u['is_verified'] ?? 0) == 1;

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text('${u['name'] ?? 'Unknown'} (${u['role'] ?? 'user'})'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u['email'] ?? 'No email'),
                  Text('Phone: ${u['phone_num'] ?? 'N/A'}'),
                  Text(
                    'Joined: ${DateFormatter.formatDateTime(u['created_at'])}',
                  ),
                ],
              ),
              trailing:
                  verified
                      ? const Text(
                        '✅ Verified',
                        style: TextStyle(color: Color(0xFF0A4423)),
                      )
                      : u['is_verified'] == -1
                      ? const Text(
                        '❌ Rejected',
                        style: TextStyle(color: Color(0xFF791317)),
                      )
                      : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed:
                                () => onAction(u['id'].toString(), 'verify'),
                            child: const Text('Verify'),
                          ),
                          TextButton(
                            onPressed:
                                () => onAction(u['id'].toString(), 'reject'),
                            child: const Text(
                              'Reject',
                              style: TextStyle(color: Color(0xFF791317)),
                            ),
                          ),
                        ],
                      ),
            ),
          );
        },
      );
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.grey.shade200,
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
              ),
              indicator: const BoxDecoration(
                color: Color.fromARGB(231, 10, 68, 35),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(text: 'Verified (${verifiedUsers.length})'),
                Tab(text: 'Unverified (${unverifiedUsers.length})'),
                Tab(text: 'Rejected (${rejectedUsers.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                buildUserList(verifiedUsers),
                buildUserList(unverifiedUsers),
                buildUserList(rejectedUsers),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- EATERIES --------------------
class EateryPage extends StatelessWidget {
  final List eateries;
  final bool isLoading;
  final Function(String, String) onAction;
  final Function(String, String) onRejectWithReason;
  final Function(String, String) onApproveConfirm;

  const EateryPage({
    super.key,
    required this.eateries,
    required this.isLoading,
    required this.onAction,
    required this.onRejectWithReason,
    required this.onApproveConfirm,
  });

  String formatLabel(String key) {
    // Remove "_base64" suffix before formatting
    key = key.replaceAll("_base64", "");

    // Convert snake_case → "Title Case"
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void showCredentialsDialog(
    BuildContext context,
    String name,
    Map<String, String> documents,
  ) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 24),
                ),
              ),
              Text(
                '$name Credentials',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 15),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: documents.entries.map((doc) {
                      final url = doc.value;
                      final label = formatLabel(doc.key);

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 1,
                                  child: url.isEmpty
                                      ? const Text(
                                          "User has not uploaded this requirement yet.",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => Dialog(
                                                child: InteractiveViewer(
                                                  child: Image.network(url),
                                                ),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              url,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(thickness: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (eateries.isEmpty) return const Center(child: Text('No eateries found'));

    final verified =
        eateries
            .where((e) => e['is_verified'] == 1)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

    final pending =
        eateries
            .where((e) => e['is_verified'] != 1)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          ExpandableTable(
            title: 'Verified Eateries (${verified.length})',
            columns: const [
              'Name',
              'Owner ID',
              'Location',
              'Verified Time',
              'Credentials',
            ],
            data: verified,
            rowBuilder:
                (e) => [
                  Text('${e['name'] ?? ''}'),
                  Text('${e['owner_id'] ?? ''}'),
                  Text('${e['location'] ?? ''}'),
                  Text(DateFormatter.formatDateTime(e['verified_time'])),
                  TextButton(
                    child: const Text(
                      'View',
                      style: TextStyle(
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    onPressed:
                        () => showCredentialsDialog(
                          context,
                          e['name'] ?? 'Eatery',
                          {
                            'Valid ID': e['valid_id_base64'] ?? '',
                            'Business Permit':
                                e['business_permit_base64'] ?? '',
                            'DTI Certificate':
                                e['dti_certificate_base64'] ?? '',
                            'Health Permit': e['health_permit_base64'] ?? '',
                          },
                        ),
                  ),
                ],
          ),
          const SizedBox(height: 20),
          ExpandableTable(
            title: 'Eatery Applications (${pending.length})',
            columns: const [
              'Name',
              'Owner ID',
              'Location',
              'Application Date',
              'Status',
              'Actions',
              'Credentials',
            ],
            data: pending,
            rowBuilder: (e) {
              final isPending = e['is_verified'] == 0;
              final statusText = isPending ? 'Pending' : 'Rejected';
              final statusColor =
                  isPending ? Color(0xFFFBAC24) : Color(0xFF791317);
              return [
                Text('${e['name'] ?? ''}'),
                Text('${e['owner_id'] ?? ''}'),
                Text('${e['location'] ?? ''}'),
                Text(DateFormatter.formatDateTime(e['created_at'] ?? '')),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (isPending)
                  Column(
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF0A4423),
                            width: 1.5,
                          ),
                          foregroundColor: Color(0xFF0A4423),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onPressed:
                            () =>
                                onApproveConfirm(e['id'].toString(), 'eatery'),

                        child: const Text('Approve'),
                      ),

                      SizedBox(height: 10),
                      TextButton(
                        style: TextButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onPressed:
                            () => onRejectWithReason(
                              e['id'].toString(),
                              'eatery',
                            ),
                        child: const Text(' Reject '),
                      ),
                    ],
                  )
                else
                  const SizedBox(),
                TextButton(
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onPressed:
                      () => showCredentialsDialog(
                        context,
                        e['name'] ?? 'Eatery',
                        {
                          'Valid ID': e['valid_id_base64'] ?? '',
                          'Business Permit': e['business_permit_base64'] ?? '',
                          'DTI Certificate': e['dti_certificate_base64'] ?? '',
                          'Health Permit': e['health_permit_base64'] ?? '',
                        },
                      ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

// -------------------- HOUSINGS --------------------
class HousingApplication extends StatelessWidget {
  final List housings;
  final bool isLoading;
  final Function(String, String) onAction;
  final Function(String, String) onRejectWithReason;
  final Function(String, String) onApproveConfirm;

  const HousingApplication({
    super.key,
    required this.housings,
    required this.isLoading,
    required this.onAction,
    required this.onRejectWithReason,
    required this.onApproveConfirm,
  });

  void showCredentialsDialog(
    BuildContext context,
    String name,
    Map<String, String> documents,
  ) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 24),
                ),
              ),
              Text(
                '$name Credentials',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 15),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: documents.entries.map((doc) {
                      final url = doc.value;
                      final label = doc.key
                          .replaceAll("_base64", "")
                          .split('_')
                          .map((w) => w[0].toUpperCase() + w.substring(1))
                          .join(' ');

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 1,
                                  child: url.isEmpty
                                      ? const Text(
                                          "User has not uploaded this requirement yet.",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => Dialog(
                                                child: InteractiveViewer(
                                                  child: Image.network(url),
                                                ),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              url,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(thickness: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (housings.isEmpty) return const Center(child: Text('No housings found'));

    final verified =
        housings
            .where((h) => h['is_verified'] == 1)
            .map((h) => Map<String, dynamic>.from(h))
            .toList();

    final pending =
        housings
            .where((h) => h['is_verified'] != 1)
            .map((h) => Map<String, dynamic>.from(h))
            .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          ExpandableTable(
            title: 'Verified Housings (${verified.length})',
            columns: const [
              'Name',
              'Owner ID',
              'Location',
              'Verified Time',
              'Credentials',
            ],
            data: verified,
            rowBuilder:
                (h) => [
                  Text('${h['name'] ?? ''}'),
                  Text('${h['owner_id'] ?? ''}'),
                  Text('${h['location'] ?? ''}'),
                  Text(DateFormatter.formatDateTime(h['verified_time'] ?? '')),

                  TextButton(
                    child: const Text(
                      'View',
                      style: TextStyle(
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    onPressed:
                        () => showCredentialsDialog(
                          context,
                          h['name'] ?? 'Housing',
                          {
                            'Valid ID': h['valid_id_base64_housing'] ?? '',
                            'Proof of Ownership':
                                h['proof_of_ownership_base64'] ?? '',
                          },
                        ),
                  ),
                ],
          ),
          const SizedBox(height: 20),
          ExpandableTable(
            title: 'Housing Applications (${pending.length})',
            columns: const [
              'Name',
              'Owner ID',
              'Location',
              'Application Date',
              'Status',
              'Actions',
              'Credentials',
            ],
            data: pending,
            rowBuilder: (h) {
              final isPending = h['is_verified'] == 0;
              final statusText = isPending ? 'Pending' : 'Rejected';
              final statusColor = isPending ? Colors.orange : Color(0xFF791317);
              return [
                Text('${h['name'] ?? ''}'),
                Text('${h['owner_id'] ?? ''}'),
                Text('${h['location'] ?? ''}'),
                Text(DateFormatter.formatDateTime(h['created_at'] ?? '')),

                Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (isPending)
                  Column(
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF0A4423),
                            width: 1.5,
                          ),
                          foregroundColor: Color(0xFF0A4423),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onPressed:
                            () =>
                                onApproveConfirm(h['id'].toString(), 'housing'),

                        child: const Text('Approve'),
                      ),
                      SizedBox(height: 10),
                      TextButton(
                        style: TextButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        onPressed:
                            () => onRejectWithReason(
                              h['id'].toString(),
                              'housing',
                            ),
                        child: const Text(' Reject '),
                      ),
                    ],
                  )
                else
                  const SizedBox(),
                TextButton(
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onPressed:
                      () => showCredentialsDialog(
                        context,
                        h['name'] ?? 'Housing',
                        {
                          'Valid ID': h['valid_id_base64_housing'] ?? '',
                          'Proof of Ownership':
                              h['proof_of_ownership_base64'] ?? '',
                        },
                      ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

// -------------------- EXPANDABLE TABLE WITH VERTICAL DIVIDERS --------------------
class ExpandableTable extends StatefulWidget {
  final String title;
  final List<String> columns;
  final List<Map<String, dynamic>> data;
  final List<Widget> Function(Map<String, dynamic>) rowBuilder;

  const ExpandableTable({
    super.key,
    required this.title,
    required this.columns,
    required this.data,
    required this.rowBuilder,
  });

  @override
  State<ExpandableTable> createState() => _ExpandableTableState();
}

class _ExpandableTableState extends State<ExpandableTable> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final displayData = expanded ? widget.data : widget.data.take(5).toList();
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive font sizes
    final titleFontSize = screenWidth < 400 ? 16.0 : 18.0;
    final columnFontSize = screenWidth < 400 ? 12.0 : 14.0;
    final rowFontSize = screenWidth < 400 ? 12.0 : 14.0;
    final horizontalPadding = screenWidth < 400 ? 8.0 : 12.0;

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.all(horizontalPadding),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0A4423),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.data.length > 5)
                    TextButton(
                      onPressed: () => setState(() => expanded = !expanded),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0A4423),
                      ),
                      child: Text(
                        expanded ? 'Collapse' : 'View All',
                        style: TextStyle(fontSize: columnFontSize),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: screenWidth * 0.75),
                  child: Table(
                    border: TableBorder.symmetric(
                      inside: const BorderSide(color: Colors.grey, width: 0.5),
                    ),
                    columnWidths: {
                      for (int i = 0; i < widget.columns.length; i++)
                        i: const FlexColumnWidth(),
                    },
                    children: [
                      // Table Header
                      TableRow(
                        decoration: BoxDecoration(color: Color(0xFF0A4423)),
                        children:
                            widget.columns
                                .map(
                                  (c) => Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      textAlign: TextAlign.center,
                                      c,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: columnFontSize,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      // Table Rows
                      ...displayData.map((row) {
                        final cells = widget.rowBuilder(row);
                        return TableRow(
                          children:
                              cells
                                  .map(
                                    (w) => Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: DefaultTextStyle(
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: rowFontSize,
                                          color: Colors.black87,
                                        ),
                                        child: w,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
