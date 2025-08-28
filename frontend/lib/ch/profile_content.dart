// lib/ch/profile_content.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_provider.dart';
import '../api_service.dart';
import 'package:image_picker/image_picker.dart';

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
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- LOGIC METHODS ---

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
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 1000;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildGeneralInfoCard(),
                          const SizedBox(height: 24),
                          _buildPasswordInfoCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _buildAvatarCard(),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildAvatarCard(),
                    const SizedBox(height: 24),
                    _buildGeneralInfoCard(),
                    const SizedBox(height: 24),
                    _buildPasswordInfoCard(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildAvatarCard() {
    final user = context.watch<AuthProvider>().user;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
  radius: 50,
  backgroundImage: user?.avatarUrl != null
      ? NetworkImage(user!.avatarUrl!)
      : const AssetImage('assets/default_avatar.png') as ImageProvider,
      
),

            const SizedBox(height: 16),
            Text(user?.name ?? 'User Name',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(user?.email ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 16),
            // The main Edit/Save button now lives here
            ElevatedButton(
              onPressed: () {
                if (_isEditing) {
                  _saveAllChanges();
                } else {
                  setState(() => _isEditing = true);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing
                      ? Colors.green
                      : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 40)),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Save Changes' : 'Edit Profile'),
            ),
            const SizedBox(height: 8),
            // Change avatar is always available
            if (!_isEditing)
              TextButton(
                onPressed: _pickAndUploadImage,
                child: const Text('Change Avatar'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('General Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        label: 'First Name',
                        controller: _firstNameController,
                        isEditing: _isEditing)),
                const SizedBox(width: 24),
                Expanded(
                    child: _buildTextField(
                        label: 'Last Name',
                        controller: _lastNameController,
                        isEditing: _isEditing)),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(
                label: 'Email', controller: _emailController, readOnly: true, isEditing: _isEditing,),
            const SizedBox(height: 24),
            _buildDropdownField(
                label: 'Gender',
                items: ['Male', 'Female', 'Prefer not to say'],
                value: 'Male',
                isEditing: _isEditing
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordInfoCard() {
    // This card is ONLY visible when in edit mode
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _isEditing
          ? Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              margin: const EdgeInsets.only(top: 0),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Password Information',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 32),
                    _buildTextField(
                        label: 'New Password',
                        controller: _newPasswordController,
                        isEditing: _isEditing,
                        isPassword: true),
                    const SizedBox(height: 24),
                    _buildTextField(
                        label: 'Confirm New Password',
                        controller: _confirmPasswordController,
                        isEditing: _isEditing,
                        isPassword: true),
                    const SizedBox(height: 8),
                    Text(
                      '* Leave blank to keep your current password.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(), // If not editing, this card is hidden
    );
  }

  // --- FORM FIELD HELPERS ---

  Widget _buildTextField(
      {required String label,
      required TextEditingController controller,
      bool readOnly = false,
      bool isPassword = false,
      required bool isEditing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly || !isEditing,
          obscureText: isPassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly || !isEditing ? Colors.grey[100] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
      {required String label,
      required String value,
      required List<String> items,
      required bool isEditing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: isEditing ? (newValue) {} : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: !isEditing ? Colors.grey[100] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }
}
