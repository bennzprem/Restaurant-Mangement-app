import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/about_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/loginpage.dart';
import 'screens/signuppage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ByteEat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFDAE952)),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/menu': (context) => const MenuScreen(),
        '/about': (context) => const AboutScreen(),
        '/contact': (context) => const ContactScreen(),
        //'/login': (context) => const LoginPage(),
        //'/signup': (context) => const SignUpPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
