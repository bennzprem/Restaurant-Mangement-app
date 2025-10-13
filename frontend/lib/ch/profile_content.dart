// lib/ch/profile_content.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth_provider.dart';
import '../api_service.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/address_management_widget.dart';

class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  // --- STATE MANAGEMENT ---
  bool _isEditing = false; // This is the master switch for edit/view mode
  bool _isLoading = false;

  // Controllers for General Information
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _nickNameController;

  // Dropdown values
  String? _selectedGender;
  String? _selectedCountry;
  String? _selectedLanguage;
  String? _selectedTimeZone;

  // Controllers for Password Information
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    // Initialize controllers with user data
    _firstNameController =
        TextEditingController(text: user?.name.split(' ').first ?? '');
    _lastNameController = TextEditingController(
        text: (user?.name.split(' ') ?? []).length > 1
            ? user!.name.split(' ').last
            : '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _nickNameController =
        TextEditingController(text: user?.name.split(' ').first ?? '');

    // Load saved profile data
    _loadSavedProfileData();
  }

  Future<void> _loadSavedProfileData() async {
    try {
      // For now, we'll initialize with empty values
      // In a real implementation, you'd fetch this from the backend
      // The values will be loaded when the user data is refreshed
      setState(() {
        _selectedGender = null;
        _selectedCountry = null;
        _selectedLanguage = null;
        _selectedTimeZone = null;
      });
    } catch (e) {
      print('Error loading saved profile data: $e');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _nickNameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- LOGIC METHODS ---

  Future<void> _saveAdditionalProfileInfo(String userId) async {
    try {
      // Prepare the profile data
      Map<String, dynamic> profileData = {};

      if (_nickNameController.text.isNotEmpty) {
        profileData['nickname'] = _nickNameController.text;
      }
      if (_selectedGender != null) {
        profileData['gender'] = _selectedGender;
      }
      if (_selectedCountry != null) {
        profileData['country'] = _selectedCountry;
      }
      if (_selectedLanguage != null) {
        profileData['language'] = _selectedLanguage;
      }
      if (_selectedTimeZone != null) {
        profileData['timezone'] = _selectedTimeZone;
      }

      // Only make API call if there's data to save
      if (profileData.isNotEmpty) {
        await ApiService().updateUserProfileInfo(userId, profileData);
        print('✅ Profile info saved to database successfully');
      }
    } catch (e) {
      print('❌ Error saving additional profile info: $e');
      rethrow; // Re-throw to show error to user
    }
  }

  Future<void> _saveAllChanges() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user!;
    bool profileUpdated = false;
    bool passwordUpdated = false;

    try {
      // --- 1. Save General Information (if changed) ---
      final newName =
          '${_firstNameController.text} ${_lastNameController.text}'.trim();
      if (newName != user.name) {
        await ApiService().updateProfile(user.id, newName);
        profileUpdated = true;
      }

      // --- 1.5. Save Additional Profile Information ---
      await _saveAdditionalProfileInfo(user.id);

      // --- 2. Save Password (if entered) ---
      if (_newPasswordController.text.isNotEmpty) {
        if (_newPasswordController.text != _confirmPasswordController.text) {
          throw Exception('Passwords do not match.');
        }
        await ApiService().changePassword(_newPasswordController.text);
        passwordUpdated = true;
      }

      // --- 3. Refresh user data and show confirmation ---
      if (profileUpdated || passwordUpdated) {
        await authProvider.refreshUserProfile();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isEditing = false; // Revert to view mode
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null || user == null) return;

    try {
      // Upload and get the new avatar URL
      final newUrl = await ApiService().uploadProfilePicture(user.id, image);

      if (newUrl != null) {
        // Update provider state immediately
        await authProvider.refreshUserProfile();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile picture updated!')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to upload profile picture.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to upload image: $e')),
      );
    }
  }

  // --- UI BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final userName = user?.name ?? 'User';
    final userEmail = user?.email ?? 'No email provided';
    final avatarUrl = user?.avatarUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileCard(userName, userEmail, avatarUrl),
          const SizedBox(height: 30),
          _buildFormSection(),
          const SizedBox(height: 30),
          _buildEmailAddressSection(userEmail),
          const SizedBox(height: 30),
          const AddressManagementWidget(),
        ],
      ),
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
                backgroundColor: const Color(0xFF8BC34A),
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
                      color: Color(0xFF8BC34A),
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
                    color: const Color(0xFF33691E),
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
              if (_isEditing) {
                _saveAllChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditing ? 'Save Changes' : 'Edit',
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
              Expanded(
                  child: _buildTextField("Full Name", _firstNameController)),
              const SizedBox(width: 20),
              Expanded(
                  child: _buildTextField("Nick Name", _nickNameController)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _buildDropdownField(
                      "Gender", ["Male", "Female", "Other"], _selectedGender,
                      (value) {
                setState(() => _selectedGender = value);
              })),
              const SizedBox(width: 20),
              Expanded(
                  child: _buildDropdownField(
                      "Country",
                      [
                        "USA",
                        "Canada",
                        "UK",
                        "India",
                        "Australia",
                        "Germany",
                        "France",
                        "Japan"
                      ],
                      _selectedCountry, (value) {
                setState(() => _selectedCountry = value);
              })),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _buildDropdownField(
                      "Language",
                      [
                        "English",
                        "Spanish",
                        "French",
                        "German",
                        "Italian",
                        "Portuguese",
                        "Chinese",
                        "Japanese"
                      ],
                      _selectedLanguage, (value) {
                setState(() => _selectedLanguage = value);
              })),
              const SizedBox(width: 20),
              Expanded(
                  child: _buildDropdownField(
                      "Time Zone",
                      ["EST", "PST", "CST", "MST", "GMT", "IST", "JST", "AEST"],
                      _selectedTimeZone, (value) {
                setState(() => _selectedTimeZone = value);
              })),
            ],
          ),
        ],
      ),
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

  Widget _buildTextField(String label, TextEditingController controller) {
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
          controller: controller,
          readOnly: !_isEditing,
          decoration: InputDecoration(
            hintText: "Your $label",
            hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
            filled: true,
            fillColor: _isEditing ? const Color(0xFFF7F8FC) : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items,
      String? selectedValue, Function(String?) onChanged) {
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
          value: selectedValue,
          decoration: InputDecoration(
            hintText: "Select $label",
            hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
            filled: true,
            fillColor: _isEditing ? const Color(0xFFF7F8FC) : Colors.grey[100],
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
          onChanged: _isEditing ? onChanged : null,
        ),
      ],
    );
  }
}
