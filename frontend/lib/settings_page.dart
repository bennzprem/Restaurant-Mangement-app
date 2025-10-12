// lib/settings_page.dart
import 'package:flutter/material.dart';
import 'theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;
  bool _isSaving = false;

  // Restaurant Information
  final TextEditingController _restaurantNameController =
      TextEditingController();
  final TextEditingController _restaurantAddressController =
      TextEditingController();
  final TextEditingController _restaurantPhoneController =
      TextEditingController();
  final TextEditingController _restaurantEmailController =
      TextEditingController();
  final TextEditingController _restaurantDescriptionController =
      TextEditingController();

  // Business Hours
  final Map<String, TimeOfDay> _openingHours = {};
  final Map<String, TimeOfDay> _closingHours = {};
  final Map<String, bool> _isOpen = {};

  // System Settings
  bool _autoAcceptOrders = false;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;
  double _deliveryRadius = 5.0;
  double _deliveryFee = 50.0;
  double _minimumOrderAmount = 200.0;
  int _orderPreparationTime = 30;

  // Theme Settings
  bool _isDarkMode = false;
  String _selectedLanguage = 'English';

  // Security Settings
  bool _requirePasswordChange = false;
  int _sessionTimeout = 30;

  @override
  void initState() {
    super.initState();
    _initializeBusinessHours();
    _loadSettings();
  }

  void _initializeBusinessHours() {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    for (String day in days) {
      _openingHours[day] = const TimeOfDay(hour: 9, minute: 0);
      _closingHours[day] = const TimeOfDay(hour: 22, minute: 0);
      _isOpen[day] = true;
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      // Load restaurant information
      _restaurantNameController.text = 'ByteEat Restaurant';
      _restaurantAddressController.text = '123 Food Street, City, State 12345';
      _restaurantPhoneController.text = '+91 9876543210';
      _restaurantEmailController.text = 'info@byteeat.com';
      _restaurantDescriptionController.text =
          'Delicious food delivered to your doorstep';

      // Load system settings from API or local storage
      // This would typically come from your backend
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      // Save settings to backend
      // This would typically involve API calls to your backend

      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _restaurantAddressController.dispose();
    _restaurantPhoneController.dispose();
    _restaurantEmailController.dispose();
    _restaurantDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Restaurant Information Section
          _buildSectionCard(
            title: 'Restaurant Information',
            icon: Icons.restaurant,
            children: [
              _buildTextField(
                controller: _restaurantNameController,
                label: 'Restaurant Name',
                icon: Icons.business,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _restaurantAddressController,
                label: 'Address',
                icon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _restaurantPhoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _restaurantEmailController,
                      label: 'Email',
                      icon: Icons.email,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _restaurantDescriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Business Hours Section
          _buildSectionCard(
            title: 'Business Hours',
            icon: Icons.access_time,
            children: [
              ...List.generate(7, (index) {
                final days = [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday'
                ];
                final day = days[index];
                return _buildBusinessHourRow(day);
              }),
            ],
          ),

          const SizedBox(height: 24),

          // System Settings Section
          _buildSectionCard(
            title: 'System Settings',
            icon: Icons.settings,
            children: [
              _buildSwitchTile(
                title: 'Auto Accept Orders',
                subtitle: 'Automatically accept incoming orders',
                value: _autoAcceptOrders,
                onChanged: (value) => setState(() => _autoAcceptOrders = value),
                icon: Icons.check_circle,
              ),
              _buildSwitchTile(
                title: 'Email Notifications',
                subtitle: 'Send email notifications for orders',
                value: _emailNotifications,
                onChanged: (value) =>
                    setState(() => _emailNotifications = value),
                icon: Icons.email,
              ),
              _buildSwitchTile(
                title: 'SMS Notifications',
                subtitle: 'Send SMS notifications for orders',
                value: _smsNotifications,
                onChanged: (value) => setState(() => _smsNotifications = value),
                icon: Icons.sms,
              ),
              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: 'Send push notifications to mobile app',
                value: _pushNotifications,
                onChanged: (value) =>
                    setState(() => _pushNotifications = value),
                icon: Icons.notifications,
              ),
              const Divider(),
              _buildSliderTile(
                title: 'Delivery Radius',
                subtitle: 'Maximum delivery distance in kilometers',
                value: _deliveryRadius,
                min: 1.0,
                max: 20.0,
                divisions: 19,
                onChanged: (value) => setState(() => _deliveryRadius = value),
                icon: Icons.location_on,
              ),
              _buildSliderTile(
                title: 'Delivery Fee',
                subtitle: 'Standard delivery fee in rupees',
                value: _deliveryFee,
                min: 0.0,
                max: 200.0,
                divisions: 40,
                onChanged: (value) => setState(() => _deliveryFee = value),
                icon: Icons.local_shipping,
              ),
              _buildSliderTile(
                title: 'Minimum Order Amount',
                subtitle: 'Minimum order value for delivery',
                value: _minimumOrderAmount,
                min: 100.0,
                max: 1000.0,
                divisions: 18,
                onChanged: (value) =>
                    setState(() => _minimumOrderAmount = value),
                icon: Icons.shopping_cart,
              ),
              _buildSliderTile(
                title: 'Order Preparation Time',
                subtitle: 'Average preparation time in minutes',
                value: _orderPreparationTime.toDouble(),
                min: 15.0,
                max: 120.0,
                divisions: 21,
                onChanged: (value) =>
                    setState(() => _orderPreparationTime = value.round()),
                icon: Icons.timer,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Theme & Display Section
          _buildSectionCard(
            title: 'Theme & Display',
            icon: Icons.palette,
            children: [
              _buildSwitchTile(
                title: 'Dark Mode',
                subtitle: 'Use dark theme throughout the app',
                value: _isDarkMode,
                onChanged: (value) => setState(() => _isDarkMode = value),
                icon: Icons.dark_mode,
              ),
              _buildDropdownTile(
                title: 'Language',
                subtitle: 'Select app language',
                value: _selectedLanguage,
                items: ['English', 'Hindi', 'Tamil', 'Telugu', 'Bengali'],
                onChanged: (value) =>
                    setState(() => _selectedLanguage = value!),
                icon: Icons.language,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Security Section
          _buildSectionCard(
            title: 'Security',
            icon: Icons.security,
            children: [
              _buildSwitchTile(
                title: 'Require Password Change',
                subtitle: 'Force password change on next login',
                value: _requirePasswordChange,
                onChanged: (value) =>
                    setState(() => _requirePasswordChange = value),
                icon: Icons.lock,
              ),
              _buildSliderTile(
                title: 'Session Timeout',
                subtitle: 'Auto logout after inactivity (minutes)',
                value: _sessionTimeout.toDouble(),
                min: 5.0,
                max: 120.0,
                divisions: 23,
                onChanged: (value) =>
                    setState(() => _sessionTimeout = value.round()),
                icon: Icons.timer_off,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Danger Zone
          _buildSectionCard(
            title: 'Danger Zone',
            icon: Icons.warning,
            color: Colors.red,
            children: [
              _buildDangerButton(
                title: 'Reset All Settings',
                subtitle: 'Reset all settings to default values',
                icon: Icons.restore,
                onPressed: () => _showResetDialog(),
              ),
              const SizedBox(height: 16),
              _buildDangerButton(
                title: 'Delete All Data',
                subtitle: 'Permanently delete all restaurant data',
                icon: Icons.delete_forever,
                onPressed: () => _showDeleteDataDialog(),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (color ?? Theme.of(context).primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color ?? Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[100]!.withOpacity(0.3),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600]!),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600]!),
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
          Text(
            '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}${title.contains('Radius') ? ' km' : title.contains('Fee') || title.contains('Amount') ? ' ₹' : title.contains('Time') ? ' min' : ''}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600]!),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        underline: Container(),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildBusinessHourRow(String day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              day,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Switch(
            value: _isOpen[day] ?? true,
            onChanged: (value) => setState(() => _isOpen[day] = value),
            activeColor: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 16),
          if (_isOpen[day] ?? true) ...[
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(context, day, true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatTime(_openingHours[day]!),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('to', style: TextStyle(color: Colors.grey[600]!)),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(context, day, false),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatTime(_closingHours[day]!),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
          ] else ...[
            const Expanded(
              child: Text(
                'Closed',
                style: TextStyle(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDangerButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600]!,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.red, size: 16),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(
      BuildContext context, String day, bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingHours[day]! : _closingHours[day]!,
    );
    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingHours[day] = picked;
        } else {
          _closingHours[day] = picked;
        }
      });
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
            'Are you sure you want to reset all settings to default values? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSettings();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
            'Are you sure you want to permanently delete all restaurant data? This action cannot be undone and will remove all orders, users, and menu items.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement delete functionality
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    setState(() {
      // Reset all settings to default values
      _autoAcceptOrders = false;
      _emailNotifications = true;
      _smsNotifications = false;
      _pushNotifications = true;
      _deliveryRadius = 5.0;
      _deliveryFee = 50.0;
      _minimumOrderAmount = 200.0;
      _orderPreparationTime = 30;
      _isDarkMode = false;
      _selectedLanguage = 'English';
      _requirePasswordChange = false;
      _sessionTimeout = 30;

      // Reset business hours
      _initializeBusinessHours();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings reset to default values'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
