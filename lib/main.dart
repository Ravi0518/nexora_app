import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

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
import 'screens/emergency_screen.dart';
import 'screens/report_incident_screen.dart';
import 'screens/nearby_rescuers_screen.dart';
import 'screens/map_screen.dart';
import 'screens/content_contribution_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      // Force Hybrid Composition (GLSurfaceView) to avoid the Texture/ImageReader maxImages crash
      mapsImplementation.useAndroidViewSurface = true;
    }
  }

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
      // First-run: show language picker → then login. Returning user: go to /home or /enthusiast-home.
      initialRoute: isLoggedIn
          ? (userRole == 'enthusiast' ? '/enthusiast-home' : '/home')
          : '/language',
      routes: {
        '/': (context) => const LanguageScreen(),
        '/language': (context) => const LanguageScreen(),

        // Auth screens — pass the saved language so they are localized from the start
        '/login': (context) => LoginScreen(lang: selectedLang),
        '/signup': (context) => SignupScreen(lang: selectedLang),
        '/forgot-password': (context) =>
            ForgotPasswordScreen(lang: selectedLang),

        '/otp': (context) => OTPScreen(userData: const {}, lang: selectedLang),
        '/verify-email': (context) => const VerifyEmailPanel(),

        // Main navigation (bottom nav) — user & enthusiast home
        '/home': (context) =>
            MainNavigation(lang: selectedLang, role: userRole ?? 'user'),

        '/enthusiast-home': (context) =>
            EnthusiastHomeScreen(lang: selectedLang),

        '/emergency': (context) => EmergencyScreen(lang: selectedLang),
        '/report-incident': (context) => const ReportIncidentScreen(),
        '/nearby-experts': (context) => const NearbyRescuersScreen(),
        '/map': (context) => const MapScreen(),
        '/content-contribution': (context) =>
            ContentContributionScreen(lang: selectedLang),

        '/admin-dashboard': (context) => const Scaffold(
              body: Center(child: Text('Admin Dashboard coming soon!')),
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
  late String _currentLang;

  @override
  void initState() {
    super.initState();
    _currentLang = widget.lang;
    _initAppData();
  }

  Future<void> _initAppData() async {
    final prefs = await SharedPreferences.getInstance();
    final String name = prefs.getString('fname') ?? 'Explorer';
    final String email = prefs.getString('email') ?? 'user@nexora.com';
    final String lang = prefs.getString('user_lang') ?? widget.lang;

    if (mounted) setState(() => _currentLang = lang);
    _buildPages(name: name, email: email, lang: lang);
  }

  void _buildPages(
      {required String name, required String email, required String lang}) {
    setState(() {
      _pages = [
        UserHomeScreen(lang: lang),
        ScanScreen(lang: lang),
        CollectionScreen(lang: lang),
        ProfileScreen(
          userData: {
            'full_name': name,
            'email': email,
            'role': widget.role,
            'language': lang,
          },
          onLanguageChanged: (newLang) async {
            final prefs = await SharedPreferences.getInstance();
            final savedName = prefs.getString('fname') ?? name;
            final savedEmail = prefs.getString('email') ?? email;
            setState(() => _currentLang = newLang);
            _buildPages(name: savedName, email: savedEmail, lang: newLang);
          },
        ),
      ];
      _isDataLoaded = true;
    });
  }

  String _navLabel(String key) {
    final labels = {
      'home': {'English': 'Home', 'සිංහල': 'මුල් පිටුව', 'தமிழ்': 'முகப்பு'},
      'identify': {
        'English': 'Identify',
        'සිංහල': 'හඳුනාගන්න',
        'தமிழ்': 'அடையாளம்'
      },
      'collection': {
        'English': 'Collection',
        'සිංහල': 'එකතුව',
        'தமிழ்': 'தொகுப்பு'
      },
      'profile': {
        'English': 'Profile',
        'සිංහල': 'පැතිකඩ',
        'தமிழ்': 'சுயවිවරம்'
      },
    };
    return labels[key]?[_currentLang] ?? labels[key]?['English'] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF66))));
    }

    return PopScope(
      // Never allow a back-swipe/button to pop the /home route (looks like logout)
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // If not on the Home tab, jump back to it
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
        // If already on Home tab, do nothing (stay in the app)
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF050F08),
          selectedItemColor: const Color(0xFF00FF66),
          unselectedItemColor: Colors.white38,
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home_filled), label: _navLabel('home')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: _navLabel('identify')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.grid_view_rounded),
                label: _navLabel('collection')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline_rounded),
                label: _navLabel('profile')),
          ],
        ),
      ),
    );
  }
}
