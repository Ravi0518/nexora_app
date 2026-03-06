import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/nexora_api_service.dart';

class EnthusiastProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final ValueChanged<String>? onLanguageChanged;

  const EnthusiastProfileScreen({
    super.key,
    required this.userData,
    this.onLanguageChanged,
  });

  @override
  State<EnthusiastProfileScreen> createState() =>
      _EnthusiastProfileScreenState();
}

class _EnthusiastProfileScreenState extends State<EnthusiastProfileScreen> {
  late String _name;
  late String _email;
  late String _phone;
  late String _lang;
  late String _org;
  late String _exp;

  bool _isEditing = false;
  bool _isLoadingProfile = true;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _orgCtrl;
  final _auth = AuthService();

  String _t(String key) => LanguageService.t(_lang, key);

  @override
  void initState() {
    super.initState();
    _name =
        widget.userData['full_name'] ?? widget.userData['fname'] ?? 'Expert';
    _email = widget.userData['email'] ?? '';
    _phone = widget.userData['phone'] ?? '';
    _lang = widget.userData['language'] ?? 'English';
    _org = widget.userData['org'] ?? '';
    _exp = widget.userData['exp']?.toString() ?? '0';

    _nameCtrl = TextEditingController(text: _name);
    _phoneCtrl = TextEditingController(text: _phone);
    _orgCtrl = TextEditingController(text: _org);

    _loadFreshProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFreshProfile() async {
    final savedLang = await LanguageService.getLang();
    final data = await NexoraApiService.getUserProfile();
    if (!mounted) return;
    setState(() {
      if (data != null) {
        _name = data['fname'] ?? _name;
        _email = data['email'] ?? _email;
        _phone = data['phone'] ?? _phone;
        _org = data['affiliation'] ?? _org;
        _exp = data['experience_years']?.toString() ?? _exp;
        _nameCtrl.text = _name;
        _phoneCtrl.text = _phone;
        _orgCtrl.text = _org;
      }
      _lang = savedLang;
      _isLoadingProfile = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: Colors.redAccent));
      return;
    }
    setState(() {
      _isEditing = false;
    });

    // Using standard auth service logic for updating basic fields
    final res = await _auth.updateProfile(
        _nameCtrl.text.trim(), _phoneCtrl.text.trim());

    // (Optional) add update logic for affiliation etc. via NexoraApiService if backend supports it
    // await NexoraApiService.updateExpertProfile(_orgCtrl.text.trim());

    if (!mounted) return;
    setState(() {
      _name = _nameCtrl.text.trim();
      _phone = _phoneCtrl.text.trim();
      _org = _orgCtrl.text.trim();
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['success']
          ? _t('profile_updated')
          : res['message'] ?? _t('update_failed')),
      backgroundColor:
          res['success'] ? const Color(0xFF00FF66) : Colors.redAccent,
    ));
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFF07120B),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF00FF66))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Expert Profile',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit,
                color: const Color(0xFF00FF66)),
            onPressed: _isEditing
                ? _saveProfile
                : () => setState(() => _isEditing = true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Head Section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF132A1C),
                    child: Text(_name.isNotEmpty ? _name[0].toUpperCase() : 'E',
                        style: const TextStyle(
                            fontSize: 40,
                            color: Color(0xFF00FF66),
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 15),
                  Text(_name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  Text('Level: Expert Rescuer',
                      style: const TextStyle(
                          color: Color(0xFF00FF66), fontSize: 14)),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Form Fields
            _buildField('Full Name', _nameCtrl, Icons.person,
                enabled: _isEditing),
            const SizedBox(height: 15),
            _buildField(
                'Email', TextEditingController(text: _email), Icons.email,
                enabled: false), // Never editable
            const SizedBox(height: 15),
            _buildField('Phone Number', _phoneCtrl, Icons.phone,
                enabled: _isEditing),
            const SizedBox(height: 15),
            _buildField('Organization/Affiliation', _orgCtrl, Icons.business,
                enabled: _isEditing),
            const SizedBox(height: 15),
            _buildField('Experience',
                TextEditingController(text: '$_exp Years'), Icons.timer,
                enabled: false),

            const SizedBox(height: 40),

            // Logout Button
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: Text(_t('logout'),
                  style: const TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, IconData icon,
      {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(color: enabled ? Colors.white : Colors.white38),
          decoration: InputDecoration(
            prefixIcon: Icon(icon,
                color: enabled ? const Color(0xFF00FF66) : Colors.white24),
            filled: true,
            fillColor: const Color(0xFF1A1F1B),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF00FF66))),
          ),
        ),
      ],
    );
  }
}
