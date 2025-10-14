// lib/manage_users_page.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'user_models.dart';

class ManageUsersPage extends StatefulWidget {
  final VoidCallback? onUserUpdated;

  const ManageUsersPage({super.key, this.onUserUpdated});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final ApiService _apiService = ApiService();
  final List<String> _roles = [
    'user',
    'admin',
    'manager',
    'employee',
    'waiter',
    'delivery',
    'kitchen'
  ];
  final TextEditingController _searchController = TextEditingController();
  List<AppUser> _allUsers = [];
  List<AppUser> _filteredUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _apiService.getAllUsers();
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          return user.name.toLowerCase().contains(query) ||
              (user.email?.toLowerCase().contains(query) ?? false) ||
              user.role.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _updateUserRole(String userId, String newRole) async {
    try {
      await _apiService.updateUserRole(userId, newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Role updated successfully!'),
            backgroundColor: Colors.green),
      );
      // Refresh the list after updating
      _loadUsers();
      // Notify parent widget to refresh dashboard
      widget.onUserUpdated?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.indigo;
      case 'employee':
        return Colors.blue;
      case 'waiter':
        return Colors.teal;
      case 'delivery':
        return Colors.orange;
      case 'kitchen':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Management',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage user accounts and roles',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Search and Refresh Row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users by name, email, or role...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    // Create some test users to demonstrate the system
                    await _apiService.createTestUser(
                      name: 'John Manager',
                      email: 'john.manager@restaurant.com',
                      role: 'manager',
                    );
                    await _apiService.createTestUser(
                      name: 'Sarah Employee',
                      email: 'sarah.employee@restaurant.com',
                      role: 'employee',
                    );
                    await _apiService.createTestUser(
                      name: 'Wendy Waiter',
                      email: 'wendy.waiter@restaurant.com',
                      role: 'waiter',
                    );
                    await _apiService.createTestUser(
                      name: 'Mike Delivery',
                      email: 'mike.delivery@restaurant.com',
                      role: 'delivery',
                    );
                    await _apiService.createTestUser(
                      name: 'Lisa Kitchen',
                      email: 'lisa.kitchen@restaurant.com',
                      role: 'kitchen',
                    );
                    await _apiService.createTestUser(
                      name: 'Alex Customer',
                      email: 'alex.customer@restaurant.com',
                      role: 'user',
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Test users created successfully! Now you can see all users.'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Refresh the user list to show the new users
                    _loadUsers();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating test users: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Add Test Users'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // User count
          Text(
            '${_filteredUsers.length} user${_filteredUsers.length == 1 ? '' : 's'} found',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading users...'),
                      ],
                    ),
                  )
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchController.text.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No users found matching your search'
                                  : 'No users found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
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
                        child: ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            final bool isAnotherAdmin = user.role == 'admin';

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ID: ${user.id}'),
                                    if (user.email != null)
                                      Text('Email: ${user.email}'),
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(user.role)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Role: ${user.role}',
                                        style: TextStyle(
                                          color: _getRoleColor(user.role),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: DropdownButton<String>(
                                  value: user.role,
                                  items: _roles.map((String role) {
                                    return DropdownMenuItem<String>(
                                      value: role,
                                      child: Text(role),
                                    );
                                  }).toList(),
                                  onChanged: isAnotherAdmin
                                      ? null
                                      : (String? newRole) {
                                          if (newRole != null &&
                                              newRole != user.role) {
                                            _updateUserRole(user.id, newRole);
                                          }
                                        },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
