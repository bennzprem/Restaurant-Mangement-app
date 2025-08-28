import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../theme_provider.dart';
import '../auth_provider.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22), // glassmorphism
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Container(
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode
                    ? Colors.grey.shade900.withOpacity(0.68)
                    : Colors.white.withOpacity(0.68),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border(
                  bottom: BorderSide(
                    color: themeProvider.isDarkMode
                        ? Colors.grey.shade700.withOpacity(0.3)
                        : Colors.white.withOpacity(0.13),
                    width: 1.0,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
              child: Row(
                children: [
                  // Logo
                  Icon(Icons.restaurant_menu_rounded,
                      color: Color(0xFFDAE952), size: 28),
                  const SizedBox(width: 14),
                  Text(
                    'Byte Eat',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.85,
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  Spacer(),

                  // Admin Button (only visible to admin users)
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.isAdmin) {
                        return Container(
                          margin: const EdgeInsets.only(right: 16),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/admin_dashboard');
                            },
                            icon: const Icon(Icons.admin_panel_settings,
                                size: 18),
                            label: const Text('Admin'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Theme Toggle Button
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFDAE952),
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {
                            themeProvider.toggleTheme();
                          },
                          icon: Icon(
                            themeProvider.isDarkMode
                                ? Icons.light_mode
                                : Icons.dark_mode,
                            color: const Color(0xFFDAE952),
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Authentication Buttons
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.isLoggedIn) {
                        // User is logged in - show profile/logout
                        return Row(
                          children: [
                            // Wrap the icon and name in an InkWell to make them clickable
                            InkWell(
                              onTap: () {
                                // This navigates to the MyProfilePage
                                Navigator.pushNamed(context, '/profile');
                              },
                              borderRadius: BorderRadius.circular(24), // Makes the splash effect look nice
                              child: Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 16),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDAE952),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                  Text(
                                    authProvider.user?.name ?? 'User',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: themeProvider.isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // The existing Logout button remains here, untouched
                            ElevatedButton(
                              onPressed: () {
                                authProvider.signOut();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Logout',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                          ],
                        );
                        
                        // // User is logged in - show profile/logout
                        // return Row(
                        //   children: [
                        //     Container(
                        //       margin: const EdgeInsets.only(right: 16),
                        //       padding: const EdgeInsets.all(8),
                        //       decoration: BoxDecoration(
                        //         color: const Color(0xFFDAE952),
                        //         borderRadius: BorderRadius.circular(20),
                        //       ),
                        //       child: Icon(
                        //         Icons.person,
                        //         color: Colors.black,
                        //         size: 20,
                        //       ),
                        //     ),
                        //     Text(
                        //       authProvider.user?.name ?? 'User',
                        //       style: TextStyle(
                        //         fontWeight: FontWeight.w600,
                        //         fontSize: 16,
                        //         color: themeProvider.isDarkMode
                        //             ? Colors.white
                        //             : Colors.black,
                        //       ),
                        //     ),
                        //     const SizedBox(width: 16),
                        //     ElevatedButton(
                        //       onPressed: () {
                        //         authProvider.signOut();
                        //       },
                        //       style: ElevatedButton.styleFrom(
                        //         backgroundColor: Colors.grey[300],
                        //         foregroundColor: Colors.black87,
                        //         padding: const EdgeInsets.symmetric(
                        //             horizontal: 20, vertical: 12),
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(24),
                        //         ),
                        //         elevation: 0,
                        //       ),
                        //       child: const Text(
                        //         'Logout',
                        //         style: TextStyle(
                        //             fontWeight: FontWeight.w600, fontSize: 15),
                        //       ),
                        //     ),
                        //   ],
                        // );
                      } else {
                        // User is not logged in - show login and sign up buttons
                        return Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: themeProvider.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                                side: BorderSide(
                                  color: const Color(0xFFDAE952),
                                  width: 2,
                                ),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDAE952),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
