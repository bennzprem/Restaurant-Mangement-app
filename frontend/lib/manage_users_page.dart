// lib/manage_users_page.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';
import 'user_models.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final ApiService _apiService = ApiService();
  late Future<List<AppUser>> _usersFuture;
  final List<String> _roles = [
    'user',
    'admin',
    'employee',
    'delivery',
    'kitchen'
  ];

  @override
  void initState() {
    super.initState();
    _usersFuture = _apiService.getAllUsers();
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
      setState(() {
        _usersFuture = _apiService.getAllUsers();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: FutureBuilder<List<AppUser>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final bool isAnotherAdmin = user.role == 'admin';

              return ListTile(
                title: Text(user.name),
                subtitle: Text('Current Role: ${user.role}'),
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
                          if (newRole != null && newRole != user.role) {
                            _updateUserRole(user.id, newRole);
                          }
                        },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
