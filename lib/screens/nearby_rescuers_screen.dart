import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyRescuersScreen extends StatelessWidget {
  const NearbyRescuersScreen({super.key});

  // Mock data for rescuers
  final List<Map<String, dynamic>> rescuers = const [
    {
      "name": "Dr. Alistair Finch",
      "role": "Certified Herpetologist",
      "distance": "2.5 km away",
      "status": "Available Now",
      "phone": "0771234567"
    },
    {
      "name": "Brenda Summers",
      "role": "Experienced Handler",
      "distance": "4.1 km away",
      "status": "Available Now",
      "phone": "0719876543"
    },
    {
      "name": "Marcus Thorne",
      "role": "Wildlife Rescue Volunteer",
      "distance": "7.8 km away",
      "status": "Responds in 15 mins",
      "phone": "0751112223"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A120A),
      appBar: AppBar(
        title: const Text("Request Assistance", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Important: Do not approach the snake. Maintain a safe distance.",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),

          // 1. MINI MAP PREVIEW
          Container(
            height: 250,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: const GoogleMap(
                initialCameraPosition: CameraPosition(target: LatLng(8.3444, 80.5024), zoom: 13),
                liteModeEnabled: true,
                zoomControlsEnabled: false,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // 2. RESCUERS LIST HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Experts Near You",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("${rescuers.length} Experts Found",
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),

          // 3. SCROLLABLE LIST OF RESCUERS
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: rescuers.length,
              itemBuilder: (context, index) {
                final expert = rescuers[index];
                return _buildRescuerCard(expert);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRescuerCard(Map<String, dynamic> expert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF0A120A),
            child: Icon(Icons.person, color: Color(0xFF00FF66)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expert['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(expert['role'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF00FF66), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(expert['status'], style: const TextStyle(color: Color(0xFF00FF66), fontSize: 11)),
                    const Text(" • ", style: TextStyle(color: Colors.white24)),
                    Text(expert['distance'], style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          // Action Buttons
          _actionCircle(Icons.chat_bubble, const Color(0xFF1A331A), const Color(0xFF00FF66), () {}),
          const SizedBox(width: 10),
          _actionCircle(Icons.phone, const Color(0xFF00FF66), Colors.black, () => _callNumber(expert['phone'])),
        ],
      ),
    );
  }

  Widget _actionCircle(IconData icon, Color bg, Color iconCol, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: iconCol, size: 20),
      ),
    );
  }

  Future<void> _callNumber(String phoneNumber) async {
    final Uri url = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}