// lib/widgets/staff_management_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../api_service.dart';
import '../user_models.dart';

class StaffManagementSection extends StatefulWidget {
  final List<AppUser> staff;
  final VoidCallback onStaffUpdated;
  final bool isLoading;

  const StaffManagementSection({
    super.key,
    required this.staff,
    required this.onStaffUpdated,
    required this.isLoading,
  });

  @override
  State<StaffManagementSection> createState() => _StaffManagementSectionState();
}

class _StaffManagementSectionState extends State<StaffManagementSection> {
  final TextEditingController _searchController = TextEditingController();
  List<AppUser> _filteredStaff = [];
  String _selectedRole = 'All';

  @override
  void initState() {
    super.initState();
    _filteredStaff = widget.staff;
    _searchController.addListener(_filterStaff);
  }

  @override
  void didUpdateWidget(StaffManagementSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.staff != widget.staff) {
      _filterStaff();
    }
  }

  void _filterStaff() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStaff = widget.staff.where((staff) {
        final matchesSearch = staff.name.toLowerCase().contains(query) ||
            (staff.email?.toLowerCase().contains(query) ?? false) ||
            staff.role.toLowerCase().contains(query);

        final matchesRole =
            _selectedRole == 'All' || staff.role == _selectedRole;

        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Staff Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.customBlack,
                ),
              ),
              ElevatedButton.icon(
                onPressed: widget.isLoading ? null : widget.onStaffUpdated,
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(widget.isLoading ? 'Loading...' : 'Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.white,
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

          // Search and Filter
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search staff by name, email, or role...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppTheme.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: AppTheme.customLightGrey.withOpacity(0.3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppTheme.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.customLightGrey.withOpacity(0.3),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                            _filterStaff();
                          });
                        },
                        items: [
                          'All',
                          'admin',
                          'manager',
                          'employee',
                          'delivery',
                          'kitchen',
                        ].map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role == 'All'
                                ? 'All Roles'
                                : role.toUpperCase()),
                          );
                        }).toList(),
                        underline: Container(),
                        isExpanded: true,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Staff Count
          Text(
            '${_filteredStaff.length} staff members found',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.customGrey,
            ),
          ),
          const SizedBox(height: 16),

          // Staff List (let ListView handle scrolling; no SingleChildScrollView above)
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStaff.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No staff members found',
                              style:
                                  TextStyle(fontSize: 18, color: AppTheme.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: widget.onStaffUpdated,
                              child: const Text('Refresh Data'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredStaff.length,
                        itemBuilder: (context, index) {
                          return _buildStaffCard(_filteredStaff[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(AppUser staff) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getRoleColor(staff.role).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: _getRoleColor(staff.role),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Staff Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.customBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  staff.email ?? 'No email provided',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.customGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getRoleColor(staff.role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        staff.role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getRoleColor(staff.role),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (staff.createdAt != null) ...[
                      Text(
                        'Joined ${DateFormat('MMM dd, yyyy').format(staff.createdAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.customGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Column(
            children: [
              IconButton(
                onPressed: () => _showStaffDetails(staff),
                icon: const Icon(Icons.info_outline),
                tooltip: 'View Details',
              ),
              IconButton(
                onPressed: () => _showEditRoleDialog(staff),
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Role',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.indigo;
      case 'employee':
        return Colors.blue;
      case 'delivery':
        return Colors.orange;
      case 'kitchen':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  void _showStaffDetails(AppUser staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(staff.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', staff.email ?? 'Not provided'),
            _buildDetailRow('Role', staff.role.toUpperCase()),
            _buildDetailRow('User ID', staff.id),
            if (staff.createdAt != null)
              _buildDetailRow('Joined',
                  DateFormat('MMM dd, yyyy').format(staff.createdAt!)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(AppUser staff) {
    final ApiService apiService = ApiService();
    String selectedRole = staff.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Role for ${staff.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select new role:'),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedRole,
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
                items: [
                  'user',
                  'admin',
                  'manager',
                  'employee',
                  'delivery',
                  'kitchen',
                ].map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role.toUpperCase()),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await apiService.updateUserRole(staff.id, selectedRole);
                  Navigator.pop(context);
                  widget.onStaffUpdated();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${staff.name}\'s role updated to ${selectedRole.toUpperCase()}'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating role: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
