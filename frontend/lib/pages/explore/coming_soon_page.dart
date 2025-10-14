import 'package:flutter/material.dart';

class ComingSoonPage extends StatelessWidget {
  final String title;
  const ComingSoonPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 56, color: Colors.orange),
            const SizedBox(height: 16),
            Text('Coming Soon: $title', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('We are building this experience. Stay tuned!'),
          ],
        ),
      ),
    );
  }
}

