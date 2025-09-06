/*BASIC ONE [THE DEFAULT] 
// lib/theme.dart 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // New color palette based on your new theme color
  static const Color primaryColor = Color(
    0xFFDAE952,
  ); // Your bright lime theme color
  static const Color accentColor = Color(
    0xFF212121,
  ); // A strong black for contrast
  static const Color backgroundColor = Color(
    0xFFF5F5F5,
  ); // Very light grey background
  static const Color surfaceColor = Colors.white; // For cards
  static const Color darkTextColor = Color(0xFF212121);
  static const Color lightTextColor = Color(0xFF757575);

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: surfaceColor,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.2),
        iconTheme: IconThemeData(color: darkTextColor),
        titleTextStyle: GoogleFonts.poppins(
          color: darkTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: TextTheme(
        // For large titles like the category name
        displayLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkTextColor,
        ),
        // For item titles
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: darkTextColor,
          fontWeight: FontWeight.w600,
        ),
        // For descriptions and subtitles
        bodyMedium: GoogleFonts.poppins(fontSize: 14, color: lightTextColor),
      ),
      // Style for the "ADD" buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}*/
/* MAIN THEME */
// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Main Theme Palette - Remapped for a more colorful UI
  static const Color primaryColor = Color(
    0xFFDAE952,
  ); // Main Lime highlight for text and accents
  static const Color primaryLight = Color(
    0xFFF3F8C5,
  ); // Lighter tint for backgrounds
  static const Color accentColor = Color(
    0xFFB3C13A,
  ); // Darker shade for borders and highlights
  static const Color darkTextColor = Color(
    0xFF2C3E50,
  ); // Primary Text & Button Background
  static const Color lightTextColor = Color(0xFF8F9DA9); // Secondary Text

  // --- COLOR CHANGES ARE HERE ---
  static const Color backgroundColor = Color(
    0xFFF3F8C5,
  ); // CHANGED: Main background is now a light lime tint from your palette
  static const Color surfaceColor = Colors
      .white; // CHANGED: Cards and AppBar are white to create a clean layer on top of the lime background
  // ------------------------------

  // Additional colors used throughout the application
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
  static const Color grey = Colors.grey;
  
  // Status colors
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color infoColor = Colors.blue;
  static const Color purpleColor = Colors.purple;
  static const Color lightGreenColor = Colors.lightGreen;
  
  // Specific color values used in the app
  static const Color customBlack = Color(0xFF212121);
  static const Color customGrey = Color(0xFF757575);
  static const Color customLightGrey = Color(0xFFF5F5F5);
  static const Color customDarkGrey = Color(0xFF2C3E50);
  static const Color customLightTextGrey = Color(0xFF8F9DA9);
  static const Color customDarkModeGrey = Color(0xFF1E1E1E);
  static const Color customLightModeGrey = Color(0xFFF8F9FA);
  static const Color customFormGrey = Color(0xFF495057);
  static const Color customBackgroundGrey = Color(0xFFE9ECEF);
  static const Color customDarkBackground = Color(0xFF0F0F10);
  static const Color customCardBackground = Color(0xFF151515);
  static const Color customYellow = Color(0xFFFFF59D);
  static const Color customLimeGreen = Color(0xFFB8C96C);
  static const Color customLightLime = Color(0xFFD4E49C);
  static const Color customDarkerGreen = Color(0xFF9EAD3A);
  static const Color customSuccessGreen = Color(0xFF4CAF50);

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor:
          backgroundColor, // Uses the new lime tint background
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor, // AppBar is white to stand out
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.2),
        iconTheme: IconThemeData(color: darkTextColor),
        titleTextStyle: GoogleFonts.poppins(
          color: darkTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkTextColor,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: darkTextColor,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, color: lightTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkTextColor,
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
/* Option 1: Professional (Deep Blue Accent)
// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette 1: Professional
  static const Color primaryColor = Color(0xFFDAE952); // Main Lime
  static const Color accentColor = Color(0xFF34495E);  // Deep Blue
  static const Color backgroundColor = Color(0xFFF4F6F8); // Light Grey BG
  static const Color surfaceColor = Colors.white;
  static const Color darkTextColor = Color(0xFF2C3E50);  // Dark Slate Blue
  static const Color lightTextColor = Color(0xFF8F9DA9);  // Muted Grey

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: surfaceColor,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.2),
        iconTheme: IconThemeData(color: darkTextColor),
        titleTextStyle: GoogleFonts.poppins(
          color: darkTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: darkTextColor),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, color: darkTextColor, fontWeight: FontWeight.w600),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, color: lightTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,     // Deep blue button
          foregroundColor: primaryColor,  // Lime text on button
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}*/

/* Option 2: Energetic Dark Mode (Purple Accent)
// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette 2: Energetic Dark Mode
  static const Color primaryColor = Color(0xFFDAE952); // Main Lime
  static const Color accentColor = Color(0xFF6A4C93); // Dark Purple
  static const Color backgroundColor = Color(0xFF2C3E50); // Dark Slate BG
  static const Color surfaceColor = Color(
    0xFF34495E,
  ); // Slightly Lighter Card BG
  static const Color darkTextColor = Colors.white; // Light text for dark BG
  static const Color lightTextColor = Color(
    0xFFBDC3C7,
  ); // Muted light grey text

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark, // Important for dark mode theming
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.2),
        iconTheme: IconThemeData(color: darkTextColor),
        titleTextStyle: GoogleFonts.poppins(
          color: darkTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkTextColor,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: darkTextColor,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, color: lightTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // Lime button
          foregroundColor: accentColor, // Purple text on button
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}*/

/* Option 3: Modern & Balanced (Teal Accent)
// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette 3: Modern & Balanced
  static const Color primaryColor = Color(0xFFDAE952); // Main Lime
  static const Color accentColor = Color(0xFF048B9A); // Dark Teal
  static const Color backgroundColor = Color(0xFFF4F6F8); // Light Grey BG
  static const Color surfaceColor = Colors.white;
  static const Color darkTextColor = Color(0xFF2C3E50); // Dark Slate Blue
  static const Color lightTextColor = Color(0xFF8F9DA9); // Muted Grey

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: surfaceColor,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.2),
        iconTheme: IconThemeData(color: darkTextColor),
        titleTextStyle: GoogleFonts.poppins(
          color: darkTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkTextColor,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: darkTextColor,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, color: lightTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor, // Dark Teal button
          foregroundColor: Colors.white, // White text on button
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}*/
