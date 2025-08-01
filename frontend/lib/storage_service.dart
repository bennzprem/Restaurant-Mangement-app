// lib/storage_service.dart
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'auth_provider.dart';

class StorageService {
  final String baseUrl =
      "http://127.0.0.1:5000"; // Ensure this matches your backend

  Future<String?> uploadProfilePicture(
    BuildContext context,
    Uint8List fileBytes,
    String fileName,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId == null) throw Exception('User not logged in');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/$userId/profile-picture'),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        'profile_picture',
        fileBytes,
        filename: fileName,
      ),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      return responseData; // Or parse JSON if you return more data
    } else {
      throw Exception('Failed to upload image');
    }
  }
}
