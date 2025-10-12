// lib/my_profile_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_provider.dart';
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
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Side Navigation (optional, for visual context)
            _buildSideNav(),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(userName),
                    const SizedBox(height: 30),
                    _buildProfileCard(userName, userEmail, avatarUrl),
                    const SizedBox(height: 30),
                    _buildFormSection(),
                    const SizedBox(height: 30),
                    _buildEmailAddressSection(userEmail),
                    const SizedBox(height: 30),
                    _buildDashboardSection(),
                    const SizedBox(height: 30),
                    _buildSettingsSection(authProvider),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A simple representation of the side navigation bar
  Widget _buildSideNav() {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 30),
      color: Colors.white,
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.dashboard_rounded, color: Color(0xFF4A5568)),
            onPressed: () {},
          ),
          const SizedBox(height: 20),
          IconButton(
            icon:
                const Icon(Icons.access_time_rounded, color: Color(0xFFCBD5E0)),
            onPressed: () {},
          ),
          const SizedBox(height: 20),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded,
                color: Color(0xFF4A5568)),
            onPressed: () {},
          ),
          const SizedBox(height: 20),
          IconButton(
            icon: const Icon(Icons.mail_outline_rounded,
                color: Color(0xFFCBD5E0)),
            onPressed: () {},
          ),
          const SizedBox(height: 20),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFFCBD5E0)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, $userName",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateTime.now().toString().split(' ')[0], // Current date
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    "Search",
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.notifications_none_outlined, color: Colors.grey),
            const SizedBox(width: 16),
            const CircleAvatar(
              backgroundImage: NetworkImage(
                  'https://placehold.co/100x100/A8D5E2/333333?text=A'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCard(
      String userName, String userEmail, String? avatarUrl) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE0F7FA),
            Color(0xFFFFF9C4),
            Color(0xFFFFE0B2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF4A90E2),
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4A90E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: GoogleFonts.inter(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text(
              "Edit",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTextField("Full Name")),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField("Nick Name")),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _buildDropdownField(
                      "Gender", ["Male", "Female", "Other"])),
              const SizedBox(width: 20),
              Expanded(
                  child:
                      _buildDropdownField("Country", ["USA", "Canada", "UK"])),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _buildDropdownField(
                      "Language", ["English", "Spanish", "French"])),
              const SizedBox(width: 20),
              Expanded(
                  child:
                      _buildDropdownField("Time Zone", ["EST", "PST", "CST"])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: "Your $label",
            hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFF7F8FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            hintText: "Select $label",
            hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFF7F8FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: GoogleFonts.inter()),
            );
          }).toList(),
          onChanged: (_) {},
        ),
      ],
    );
  }

  Widget _buildEmailAddressSection(String userEmail) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "My email Address",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE3F2FD),
                ),
                child: const Icon(Icons.mail_outline, color: Color(0xFF4A90E2)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userEmail,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "1 month ago",
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, color: Color(0xFF4A90E2)),
            label: Text(
              "Add Email Address",
              style: GoogleFonts.inter(color: Color(0xFF4A90E2)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4A90E2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDashboardSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "My Dashboard",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<dynamic>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text('Could not load stats.',
                        style: GoogleFonts.inter()));
              }
              if (!snapshot.hasData) {
                return Center(
                    child: Text('No stats available.',
                        style: GoogleFonts.inter()));
              }

              final orderCount = snapshot.data![0].length.toString();
              final reservationCount = snapshot.data![1].length.toString();

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.history,
                      label: 'Total Orders',
                      value: orderCount,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.calendar_today,
                      label: 'Reservations',
                      value: reservationCount,
                      color: Colors.blue,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Account Settings",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
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
            icon: Icons.calendar_month_outlined,
            title: 'My Reservations',
            onTap: () {
              Navigator.pushNamed(context, '/booking-history');
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: Text(
                'Logout',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              onPressed: () async {
                await authProvider.signOut();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for each clickable option
  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4A90E2)),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2D3748),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF4A90E2)),
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
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
