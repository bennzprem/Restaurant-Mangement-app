import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_provider.dart';
import 'qr_scanner_page.dart';
import 'theme.dart';

class WaiterTableClaimPage extends StatefulWidget {
  const WaiterTableClaimPage({super.key});

  @override
  State<WaiterTableClaimPage> createState() => _WaiterTableClaimPageState();
}

class _WaiterTableClaimPageState extends State<WaiterTableClaimPage> {
  final ApiService _api = ApiService();
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;

  Future<void> _scanQr() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerPage()),
    );
    if (code != null && code.isNotEmpty) {
      _codeController.text = code.toUpperCase();
      _claim();
    }
  }

  Future<void> _claim() async {
    final auth = context.read<AuthProvider>();
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a table code.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _api.claimTableSession(
        sessionCode: _codeController.text.trim().toUpperCase(),
        waiterId: auth.user!.id,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).custom.successColor,
          content: Text('Claimed table ${res['tableNumber']} successfully'),
        ),
      );
      // Redirect to menu with table session context for waiter ordering
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/menu',
          arguments: {
            'tableSessionId': res['sessionId'],
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).custom.errorColor,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Claim Table')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _loading ? null : _scanQr,
              icon: const Icon(Icons.qr_code_scanner, size: 28),
              label: const Text('Scan QR Code', style: TextStyle(fontSize: 18)),
              style:
                  ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Row(children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text('OR'),
                ),
                Expanded(child: Divider()),
              ]),
            ),
            Text('Enter Table Code',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'E.g., TBL001',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _claim,
              style:
                  ElevatedButton.styleFrom(padding: const EdgeInsets.all(14)),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Claim Table'),
            ),
          ],
        ),
      ),
    );
  }
}
