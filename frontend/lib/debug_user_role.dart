// lib/debug_user_role.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'api_service.dart';

class DebugUserRole extends StatefulWidget {
  const DebugUserRole({super.key});

  @override
  State<DebugUserRole> createState() => _DebugUserRoleState();
}

class _DebugUserRoleState extends State<DebugUserRole> {
  final ApiService _apiService = ApiService();
  String _debugInfo = 'Loading...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final auth = context.read<AuthProvider>();
      final user = auth.user;

      if (user == null) {
        setState(() {
          _debugInfo = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      // Get all users to see what's in the database
      final allUsers = await _apiService.getAllUsers();
      final currentUserInDb = allUsers.firstWhere(
        (u) => u.id == user.id,
        orElse: () => user,
      );

      final debugText = '''
=== USER ROLE DEBUG INFO ===
Current User (from Auth):
- ID: ${user.id}
- Name: ${user.name}
- Email: ${user.email}
- Role: ${user.role}

User in Database:
- ID: ${currentUserInDb.id}
- Name: ${currentUserInDb.name}
- Email: ${currentUserInDb.email}
- Role: ${currentUserInDb.role}

Auth Provider Checks:
- isLoggedIn: ${auth.isLoggedIn}
- isAdmin: ${auth.isAdmin}
- isManager: ${auth.isManager}
- isEmployee: ${auth.isEmployee}
- isWaiter: ${auth.isWaiter}
- isDelivery: ${auth.isDelivery}
- isKitchen: ${auth.isKitchen}

All Users in Database:
${allUsers.map((u) => '- ${u.name} (${u.email}): ${u.role}').join('\n')}
============================
''';

      setState(() {
        _debugInfo = debugText;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Error loading debug info: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _setUserRoleToManager() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final auth = context.read<AuthProvider>();
      final user = auth.user;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user logged in')),
        );
        return;
      }

      await _apiService.updateUserRole(user.id, 'manager');

      // Refresh the user profile
      await auth.refreshUserProfile();

      // Reload debug info
      await _loadDebugInfo();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User role updated to manager!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug User Role'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Text(
                      _debugInfo,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _loadDebugInfo,
                      child: const Text('Refresh Debug Info'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _setUserRoleToManager,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Set Role to Manager'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
