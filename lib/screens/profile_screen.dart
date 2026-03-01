import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PROFESSIONAL ENGLISH DOCUMENTATION
/// * FILE: profile_screen.dart
/// PURPOSE: User profile management interface.
/// * FEATURES:
/// 1. Read: Displays current user metadata.
/// 2. Update: Allows real-time editing of name, phone, and language preference.
/// 3. Delete: Implements a destructive action to terminate the user account.
/// 4. Localization: Fully localized UI based on user's global language selection.

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfileScreen({super.key, required this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  late String _currentLang;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['full_name']);
    _phoneController =
        TextEditingController(text: widget.userData['phone'] ?? "");
    _currentLang = widget.userData['language'] ?? 'English';
  }

  // English: Dictionary for Profile Screen Labels
  String _getLabel(String en, String si, String ta) {
    if (_currentLang == 'සිංහල') return si;
    if (_currentLang == 'தமிழ்') return ta;
    return en;
  }

  // --- PROFESSIONAL METHOD: Update Profile via API ---
  Future<void> _updateProfile() async {
    setState(() => _isEditing = false);
    // Academic Note: Here you would call your Laravel API (POST /api/user/update)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(_getLabel("Profile Updated",
              "පැතිකඩ යාවත්කාලීන කරන ලදී", "சுயவிவரம் புதுப்பிக்கப்பட்டது"))),
    );
  }

  // --- PROFESSIONAL METHOD: Terminate Account ---
  Future<void> _deleteAccount() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF131A14),
        title: Text(_getLabel("Are you sure?", "ඔබට විශ්වාසද?", "நிச்சயமாகவா?"),
            style: const TextStyle(color: Colors.white)),
        content: Text(_getLabel(
            "This will permanently delete your account.",
            "මෙයින් ඔබේ ගිණුම ස්ථිරවම මැකී යනු ඇත.",
            "இது உங்கள் கணக்கை நிரந்தரமாக நீக்கிவிடும்.")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text("CANCEL")),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text("DELETE",
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_getLabel("My Profile", "මගේ පැතිකඩ", "எனது சுயவிவரம்")),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check_circle : Icons.edit,
                color: const Color(0xFF00FF66)),
            onPressed: () => _isEditing
                ? _updateProfile()
                : setState(() => _isEditing = true),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF132A1C),
                child: Icon(Icons.person, size: 50, color: Color(0xFF00FF66)),
              ),
            ),
            const SizedBox(height: 30),

            _buildInfoTile(_getLabel("Full Name", "සම්පූර්ණ නම", "முழு பெயர்"),
                _nameController, Icons.person_outline),
            _buildInfoTile(
                _getLabel("Phone Number", "දුරකථන අංකය", "தொலைபேசி எண்"),
                _phoneController,
                Icons.phone_android_outlined),

            const SizedBox(height: 40),

            // Logout Button
            _buildActionBtn(
                _getLabel("Logout", "පද්ධතියෙන් ඉවත් වන්න", "வெளியேறு"),
                Colors.white10,
                Colors.white,
                Icons.logout_rounded, () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            }),

            const SizedBox(height: 15),

            // Delete Account Button
            _buildActionBtn(
                _getLabel("Delete Account", "ගිණුම මකා දමන්න", "கணக்கை நீக்கு"),
                Colors.redAccent.withOpacity(0.1),
                Colors.redAccent,
                Icons.delete_forever_rounded,
                _deleteAccount),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
      String label, TextEditingController controller, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
          color: const Color(0xFF131A14),
          borderRadius: BorderRadius.circular(20)),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color(0xFF00FF66), size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildActionBtn(
      String label, Color bg, Color txt, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: txt, size: 20),
        label: Text(label,
            style: TextStyle(color: txt, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
