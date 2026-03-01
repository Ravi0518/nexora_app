import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String firstName = "Ravindu";
  String userRole = "General Public";

  // --- LOGIC: Call Emergency 119 ---
  Future<void> _callEmergency() async {
    final Uri url = Uri.parse('tel:119');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  _buildHeader(),
                  const SizedBox(height: 40),

                  // QUICK SCAN: Opens Scan Screen
                  _buildScanHeroCard(),

                  const SizedBox(height: 35),
                  _buildStatsRow(),
                  const SizedBox(height: 35),
                  const Text("Quick Services",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildServiceGrid(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello, $firstName",
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(userRole, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
        const CircleAvatar(
          radius: 26,
          backgroundColor: Color(0xFF131A14),
          child: Icon(Icons.person_outline, color: Color(0xFF00FF66)),
        )
      ],
    );
  }

  Widget _buildScanHeroCard() {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/scan'),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF131A14),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF00FF66).withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.center_focus_weak, color: Color(0xFF00FF66), size: 60),
            const SizedBox(height: 15),
            const Text("Quick Scan", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Identify species instantly", style: TextStyle(color: Colors.white38, fontSize: 14)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF66),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text("OPEN CAMERA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statItem("12", "Species"),
        const SizedBox(width: 15),
        _statItem("24/7", "Support"),
        const SizedBox(width: 15),
        _statItem("Live", "Map"),
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: const Color(0xFF131A14), borderRadius: BorderRadius.circular(18)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Color(0xFF00FF66), fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.3,
      children: [
        _serviceCard("Report Sighting", Icons.add_location_alt, Colors.orangeAccent, () {
          // Add Report Sighting Navigation here
        }),
        _serviceCard("Emergency", Icons.phone_forwarded, Colors.redAccent, _callEmergency),
        _serviceCard("Knowledge Hub", Icons.auto_stories, Colors.blueAccent, () {
          Navigator.pushNamed(context, '/collection'); // Knowledge Hub opens collection
        }),
        _serviceCard("Nearby Experts", Icons.people_alt, Colors.purpleAccent, () {
          // Add Experts Navigation here
        }),
      ],
    );
  }

  Widget _serviceCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF131A14), borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}