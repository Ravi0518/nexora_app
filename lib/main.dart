import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import all required screens
import 'screens/splash_screen.dart';
import 'screens/language_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/user_home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/enthusiast_home_screen.dart';
import 'screens/verify_email_panel.dart';
import 'screens/otp_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final String? token = prefs.getString('token');
  final String? role = prefs.getString('role');
  final String lang = prefs.getString('user_lang') ?? 'English';
  final bool isGuest = prefs.getBool('is_guest') ?? false;

  runApp(NexoraApp(
    isLoggedIn: token != null || isGuest,
    userRole: role,
    selectedLang: lang,
  ));
}

class NexoraApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? userRole;
  final String selectedLang;

  const NexoraApp({
    super.key,
    required this.isLoggedIn,
    this.userRole,
    required this.selectedLang,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nexora App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00FF66),
        scaffoldBackgroundColor: const Color(0xFF07120B),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      initialRoute: isLoggedIn ? '/home' : '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/language': (context) => const LanguageScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        // main.dart routes:
        '/otp': (context) => const OTPScreen(userData: {}), // Placeholder

        // CRITICAL FIX: Registered the Verification Panel route
        '/verify-email': (context) => const VerifyEmailPanel(),

        // Main flow for general users
        '/home': (context) => MainNavigation(
            lang: selectedLang, role: userRole ?? 'general_public'),

        '/enthusiast-home': (context) =>
            EnthusiastHomeScreen(lang: selectedLang),

        '/admin-dashboard': (context) => const Scaffold(
              body: Center(child: Text("Admin Dashboard coming soon!")),
            ),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  final String lang;
  final String role;
  const MainNavigation({super.key, required this.lang, required this.role});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  List<Widget> _pages = [];
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _initAppData();
  }

  Future<void> _initAppData() async {
    final prefs = await SharedPreferences.getInstance();

    final String name = prefs.getString('fname') ?? 'Explorer';
    final String email = prefs.getString('email') ?? 'user@nexora.com';

    setState(() {
      _pages = [
        const UserHomeScreen(),
        ScanScreen(lang: widget.lang),
        CollectionScreen(lang: widget.lang),
        ProfileScreen(
            userData: {'full_name': name, 'email': email, 'role': widget.role}),
      ];
      _isDataLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF66))));
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF050F08),
        selectedItemColor: const Color(0xFF00FF66),
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded), label: 'Identify'),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), label: 'Collection'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
