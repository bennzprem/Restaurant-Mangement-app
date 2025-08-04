import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_provider.dart';
import 'menu_screen.dart';
import 'qr_scanner_page.dart'; // Import the new scanner page
import 'theme.dart';

class OrderFromTablePage extends StatefulWidget {
  const OrderFromTablePage({super.key});

  @override
  State<OrderFromTablePage> createState() => _OrderFromTablePageState();
}

class _OrderFromTablePageState extends State<OrderFromTablePage> {
  final TextEditingController _codeController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _validateCodeAndProceed() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isLoggedIn) {
      final loginSuccess = await Navigator.pushNamed(context, '/login');
      if (loginSuccess != true) return;
    }

    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or scan a table code.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sessionData = await _apiService
          .startTableSession(_codeController.text.toUpperCase());
      final tableNumber = sessionData['tableNumber'];
      final sessionId = sessionData['sessionId'];

      await _showConfirmationDialog(tableNumber, sessionId);
    } catch (e) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invalid Table Code'),
          // We clean up the error message to be more user-friendly
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                // This button closes the dialog
                Navigator.of(ctx).pop();
              },
            )
          ],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showConfirmationDialog(
      int tableNumber, String sessionId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Table Confirmed!'),
          content: Text('Welcome to Table $tableNumber.',
              style: const TextStyle(fontSize: 18)),
          actions: <Widget>[
            TextButton(
              child: const Text('Start Order'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MenuScreen(
                        tableSessionId: sessionId), // TODO: Pass sessionId
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _scanQrCode() async {
    // Navigate to the scanner page and wait for a result
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerPage()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      // If a code is scanned, update the text field and automatically find the table
      _codeController.text = scannedCode;
      _validateCodeAndProceed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order from Table')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Scan QR Code Card ---
            OutlinedButton.icon(
              icon: const Icon(Icons.qr_code_scanner, size: 36),
              label: const Text('Scan QR Code', style: TextStyle(fontSize: 18)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _scanQrCode,
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Row(children: [
                Expanded(child: Divider()),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('OR')),
                Expanded(child: Divider()),
              ]),
            ),

            // --- Enter Code Section ---
            Text('Enter Table Code Manually',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4),
              decoration: const InputDecoration(
                hintText: 'E.G., TBL000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading ? null : _validateCodeAndProceed,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Find Table'),
            ),
          ],
        ),
      ),
    );
  }
}
