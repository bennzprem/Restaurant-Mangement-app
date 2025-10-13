import 'dart:math';

class PickupCodeGenerator {
  static String generatePickupCode() {
    // Generate a random 4-digit code
    final random = Random();
    final code =
        random.nextInt(9000) + 1000; // Ensures 4-digit number (1000-9999)
    return code.toString();
  }

  static String generateUniquePickupCode(List<String> existingCodes) {
    String code;
    int attempts = 0;
    const maxAttempts = 100; // Prevent infinite loop

    do {
      code = generatePickupCode();
      attempts++;
    } while (existingCodes.contains(code) && attempts < maxAttempts);

    // If we couldn't generate a unique code after max attempts, append timestamp
    if (attempts >= maxAttempts) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      code = code.substring(0, 2) + timestamp.substring(timestamp.length - 2);
    }

    return code;
  }
}

