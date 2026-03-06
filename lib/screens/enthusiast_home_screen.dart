import 'package:flutter/material.dart';
import '../services/auth_service.dart';

import '../services/nexora_api_service.dart';
import '../services/location_service.dart';
import 'enthusiast_dashboard_tab.dart';
import 'enthusiast_requests_tab.dart';
import 'scan_screen.dart';
import 'enthusiast_history_tab.dart';
import 'enthusiast_profile_screen.dart';

class EnthusiastHomeScreen extends StatefulWidget {
  final String lang;

  const EnthusiastHomeScreen({super.key, required this.lang});

  @override
  State<EnthusiastHomeScreen> createState() => _EnthusiastHomeScreenState();
}

class _EnthusiastHomeScreenState extends State<EnthusiastHomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    LocationService().startTracking();
  }

  @override
  void dispose() {
    LocationService().stopTracking();
    super.dispose();
  }

  // To handle lang updates if changed in profile tab
  @override
  void didUpdateWidget(covariant EnthusiastHomeScreen oldWidget) {
    if (oldWidget.lang != widget.lang) {
      setState(() {});
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _loadUser() async {
    final data = await NexoraApiService.getUserProfile();
    if (mounted) {
      setState(() {
        _userData = data ?? {};
        _isLoading = false;
      });

      // Immediately push GPS once profile (and token) are confirmed valid
      if ((data?['role'] ?? '') == 'enthusiast') {
        _pushLocationNow();
      }
    }
  }

  /// Push current GPS to the backend right away (fire-and-forget).
  Future<void> _pushLocationNow() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      if (pos != null) {
        await NexoraApiService.updateExpertLocation(
          pos.latitude,
          pos.longitude,
        );
      }
    } catch (_) {
      // Not critical — background stream will retry on next movement
    }
  }

  List<Widget> _buildPages() {
    return [
      EnthusiastDashboardTab(userData: _userData),
      EnthusiastRequestsTab(lang: widget.lang),
      ScanScreen(lang: widget.lang),
      EnthusiastHistoryTab(lang: widget.lang),
      EnthusiastProfileScreen(
        userData: _userData,
        onLanguageChanged: (newLang) {
          // You could trigger a re-render here if you pass a callback up
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF07120B),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF00FF66))),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF07120B),
        appBar: AppBar(
          title: Image.asset('assets/images/nexor.png', height: 35),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: _buildDrawer(context),
        body: IndexedStack(
          index: _selectedIndex,
          children: _buildPages(),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.only(bottom: 20, top: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF0A140A),
            border: Border(top: BorderSide(color: Colors.white10, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(0, Icons.dashboard_rounded, 'Dashboard'),
              _navItem(1, Icons.notifications_active_rounded, 'Requests'),
              _navItem(2, Icons.camera_alt_rounded, 'Scan', isFab: true),
              _navItem(3, Icons.history_rounded, 'History'),
              _navItem(4, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label,
      {bool isFab = false}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFF00FF66) : Colors.white24;

    if (isFab) {
      return GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00FF66),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FF66).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: const Icon(Icons.camera_alt_rounded,
              color: Colors.black, size: 28),
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF07120B),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF131A14)),
            child: Row(
              children: [
                CircleAvatar(
                    backgroundColor: const Color(0xFF00FF66),
                    child: Text(_userData['fname']?.substring(0, 1) ?? 'E',
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold))),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_userData['fname'] ?? 'Expert',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const Text('Rescuer',
                        style:
                            TextStyle(color: Color(0xFF00FF66), fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title:
                const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await AuthService().logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
