// lib/my_profile_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'theme.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';
import 'order_history_page.dart';
import 'api_service.dart'; // Ensure ApiService is imported

// CHANGED: Converted to a StatefulWidget to handle image picking
class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final ImagePicker _picker = ImagePicker();

  final ApiService _apiService = ApiService(); // Add ApiService instance
  late Future<List<dynamic>> _statsFuture; // Future to hold our data

  @override
  void initState() {
    super.initState();
    // Fetch data when the page loads
    _loadUserStats();
  }

  void _loadUserStats() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;
    final userId = authProvider.user?.id;

    if (token != null && userId != null) {
      setState(() {
        // Use Future.wait to fetch both sets of data simultaneously
        _statsFuture = Future.wait([
          _apiService.fetchOrderHistory(userId),
          _apiService.getReservations(token),
        ]);
      });
    } else {
      // Handle case where user is not logged in
      _statsFuture = Future.value([[], []]);
    }
  }

  // In lib/my_profile_page.dart

  // This is the function to handle picking and uploading the image
  Future<void> _pickAndUploadImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user; // Get the user object
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null || user == null) {
      return; // User canceled or is not logged in
    }

    try {
      // CORRECTED: We now call ApiService and pass the userId and the image file
      // Make sure you have an instance of ApiService available in this class
      // final ApiService _apiService = ApiService();
      await ApiService().uploadProfilePicture(user.id, image);

      // Refresh user data to get the new avatar_url
      await authProvider.refreshUserProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated!')),
      );
    } catch (e) {
      print('Caught error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use context.watch here so the UI rebuilds when the user data changes
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    // CORRECTED: Get data directly from the user object's properties
    final userName = user?.name ?? 'User';
    final userEmail = user?.email ?? 'No email provided';
    final avatarUrl = user?.avatarUrl; // This comes from your AppUser model

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).surfaceColor,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // --- Profile Header ---
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // THIS IS THE NEW PROFILE PICTURE WIDGET
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).primaryLight,
                      // Display the uploaded image if it exists
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                color: Theme.of(context).darkTextColor,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).darkTextColor,
                        child: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _pickAndUploadImage,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(userName, style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 4),
                Text(userEmail, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
// --- ch start - christo
          const SizedBox(height: 24),

          // --- NEW: USER DASHBOARD SECTION ---
          _buildSectionHeader(context, 'My Dashboard'),
          FutureBuilder<List<dynamic>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show a simple loading indicator while fetching data
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Could not load stats.'));
              }
              if (!snapshot.hasData) {
                return const Center(child: Text('No stats available.'));
              }

              // snapshot.data contains a list: [orderList, reservationList]
              final orderCount = snapshot.data![0].length.toString();
              final reservationCount = snapshot.data![1].length.toString();

              // This is the Row you already built, but now with real data
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.history,
                      label: 'Total Orders',
                      value: orderCount, // Use real data
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.calendar_today,
                      label: 'Reservations',
                      value: reservationCount, // Use real data
                      color: Colors.blue,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
// ------------------------------------
          // --- ch end - christo

          // // --- Settings Section ---
          // _buildSectionHeader(context, 'Account Settings'),
          // const SizedBox(height: 24),

          // --- Settings Section (Logic is unchanged) ---
          _buildSectionHeader(context, 'Account Settings'),
          _buildProfileOption(
            context,
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
          ),
          _buildProfileOption(
            context,
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordPage(),
                ),
              );
            },
          ),
          _buildProfileOption(
            context,
            icon: Icons.history_outlined,
            title: 'Order History',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryPage(),
                ),
              );
            },
          ),
          _buildProfileOption(
            context,
            icon: Icons.calendar_month_outlined, // Icon for reservations
            title: 'My Reservations',
            onTap: () {
              // This uses the named route you created in main.dart
              Navigator.pushNamed(context, '/booking-history');
            },
          ),
          const SizedBox(height: 24),

          // --- Logout Button (Logic is unchanged) ---
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            onPressed: () async {
              await authProvider.signOut();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  // Helper widget for section titles (Logic is unchanged)
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).lightTextColor,
            ),
      ),
    );
  }

  // Helper widget for each clickable option (Logic is unchanged)
  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).darkTextColor),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

// Helper widget for a dashboard statistic card
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
