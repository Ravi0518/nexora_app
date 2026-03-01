import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/nexora_api_service.dart';

/// Profile Screen — view, edit name/phone, change language, delete account.
class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  /// Called with the new language label when user changes language.
  final ValueChanged<String>? onLanguageChanged;

  const ProfileScreen({
    super.key,
    required this.userData,
    this.onLanguageChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── STATE ─────────────────────────────────────────────────────────────────
  late String _name;
  late String _email;
  late String _phone;
  late String _lang;
  late String _role;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isLoadingProfile = true;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  final _auth = AuthService();

  // ── LANGUAGE ──────────────────────────────────────────────────────────────
  static const _langs = [
    {'label': 'English', 'native': 'English', 'sub': 'Global'},
    {'label': 'සිංහල', 'native': 'සිංහල', 'sub': 'Sinhala'},
    {'label': 'தமிழ்', 'native': 'தமிழ்', 'sub': 'Tamil'},
  ];

  String _t(String key) => LanguageService.t(_lang, key);

  // ── LIFECYCLE ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _name = widget.userData['full_name'] ?? widget.userData['fname'] ?? 'User';
    _email = widget.userData['email'] ?? '';
    _phone = widget.userData['phone'] ?? '';
    _role = widget.userData['role'] ?? 'user';
    _lang = widget.userData['language'] ?? 'English';
    _nameCtrl = TextEditingController(text: _name);
    _phoneCtrl = TextEditingController(text: _phone);
    _loadFreshProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── API CALLS ─────────────────────────────────────────────────────────────
  Future<void> _loadFreshProfile() async {
    // Also load saved language
    final savedLang = await LanguageService.getLang();
    final data = await NexoraApiService.getUserProfile();
    if (!mounted) return;
    setState(() {
      if (data != null) {
        _name = data['fname'] ?? _name;
        _email = data['email'] ?? _email;
        _phone = data['phone'] ?? _phone;
        _role = data['role'] ?? _role;
        _nameCtrl.text = _name;
        _phoneCtrl.text = _phone;
      }
      _lang = savedLang;
      _isLoadingProfile = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack(
          _t('profile_updated').contains('updat')
              ? 'Name cannot be empty'
              : 'නම හිස් විය නොහැක',
          Colors.redAccent);
      return;
    }
    setState(() {
      _isEditing = false;
      _isSaving = true;
    });
    final res = await _auth.updateProfile(
        _nameCtrl.text.trim(), _phoneCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _name = _nameCtrl.text.trim();
      _phone = _phoneCtrl.text.trim();
    });
    _snack(
      res['success']
          ? _t('profile_updated')
          : (res['message'] ?? _t('update_failed')),
      res['success'] ? const Color(0xFF00FF66) : Colors.redAccent,
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showDeleteDialog();
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    final res = await _auth.deleteAccount();
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (res['success'] == true) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Even if API fails, clear prefs and return to login
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<bool?> _showDeleteDialog() => showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF131A14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              _lang == 'සිංහල'
                  ? 'ගිණුම මකන්නද?'
                  : _lang == 'தமிழ்'
                      ? 'கணக்கை நீக்கவா?'
                      : 'Delete Account?',
              style: const TextStyle(color: Colors.white, fontSize: 17),
            ),
          ]),
          content: Text(
            _lang == 'සිංහල'
                ? 'ඔබේ ගිණුම සොකො ලෙස** ముhide මකා දමනු ලැhe. මෙය නොකෙළිය නොහැකිය.'
                : _lang == 'தமிழ்'
                    ? 'உங்கள் கணக்கு நிரந்தரமாக நீக்கப்படும். இதை செயல்தவிர்க்க முடியாது.'
                    : 'Your account will be permanently deleted.\nThis action cannot be undone.',
            style: const TextStyle(
                color: Colors.white60, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(
                _lang == 'සිංහල'
                    ? 'අවලංගු කරන්න'
                    : _lang == 'தமிழ்'
                        ? 'ரத்துசெய்'
                        : 'Cancel',
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(c, true),
              child: Text(
                _lang == 'සිංහල'
                    ? 'මකන්න'
                    : _lang == 'தமிழ்'
                        ? 'நீக்கு'
                        : 'Delete',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

  Future<void> _changeLanguage() async {
    String selected = _lang;
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF131A14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                _lang == 'සිංහල'
                    ? 'භාෂාව වෙනස් කරන්න'
                    : _lang == 'தமிழ்'
                        ? 'மொழியை மாற்று'
                        : 'Change Language',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ..._langs.map((l) {
                final isActive = selected == l['label'];
                return GestureDetector(
                  onTap: () => setModal(() => selected = l['label']!),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF00FF66).withValues(alpha: 0.1)
                          : const Color(0xFF0D1A10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isActive ? const Color(0xFF00FF66) : Colors.white12,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l['native']!,
                                  style: TextStyle(
                                      color: isActive
                                          ? const Color(0xFF00FF66)
                                          : Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text(l['sub']!,
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFF00FF66)
                                  : Colors.white24,
                              width: 2,
                            ),
                            color: isActive
                                ? const Color(0xFF00FF66).withValues(alpha: 0.2)
                                : Colors.transparent,
                          ),
                          child: isActive
                              ? const Icon(Icons.check,
                                  color: Color(0xFF00FF66), size: 16)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF66),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx, selected),
                  child: Text(
                    _lang == 'සිංහල'
                        ? 'සුරකින්න'
                        : _lang == 'தமிழ்'
                            ? 'சேமி'
                            : 'Apply',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result != _lang) {
      await LanguageService.setLang(result);
      if (!mounted) return;
      setState(() => _lang = result);
      widget.onLanguageChanged?.call(result);
      _snack(
        result == 'සිංහල'
            ? 'භාෂාව සිංහලට වෙනස් විය'
            : result == 'தமிழ்'
                ? 'மொழி தமிழுக்கு மாற்றப்பட்டது'
                : 'Language changed to English',
        const Color(0xFF00FF66),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFF07120B),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF00FF66))),
      );
    }

    final roleBadge = _role == 'enthusiast'
        ? (_lang == 'සිංහල'
            ? 'උත්සාහකයා'
            : _lang == 'தமிழ்'
                ? 'ஆர்வலர்'
                : 'Enthusiast')
        : (_lang == 'සිංහල'
            ? 'සාමාන්‍ය පරිශීලක'
            : _lang == 'தமிழ்'
                ? 'பயனர்'
                : 'General User');

    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _lang == 'සිංහල'
              ? 'මගේ ගිණුම'
              : _lang == 'தமிழ்'
                  ? 'என் கணக்கு'
                  : 'My Account',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving || _isDeleting)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Color(0xFF00FF66), strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _isEditing
                  ? _saveProfile
                  : () => setState(() => _isEditing = true),
              child: Text(
                _isEditing
                    ? (_lang == 'සිංහල'
                        ? 'සුරකින්න'
                        : _lang == 'தமிழ்'
                            ? 'சேமி'
                            : 'Save')
                    : (_lang == 'සිංහල'
                        ? 'සංස්කරණය'
                        : _lang == 'தமிழ்'
                            ? 'திருத்து'
                            : 'Edit'),
                style: const TextStyle(
                    color: Color(0xFF00FF66), fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── AVATAR SECTION ─────────────────────────────────────────────
            _buildAvatarSection(roleBadge),
            const SizedBox(height: 28),

            // ── PROFILE INFORMATION ────────────────────────────────────────
            _sectionHeader(
              _lang == 'සිංහල'
                  ? 'පෞද්ගලික තොරතුරු'
                  : _lang == 'தமிழ்'
                      ? 'சுயவிவர தகவல்'
                      : 'PROFILE INFORMATION',
            ),
            _infoTile(
              icon: Icons.person_outlined,
              title: _lang == 'සිංහල'
                  ? 'සම්පූර්ණ නම'
                  : _lang == 'தமிழ்'
                      ? 'முழு பெயர்'
                      : 'Full Name',
              displayValue: _name,
              ctrl: _nameCtrl,
              editable: true,
            ),
            _infoTile(
              icon: Icons.alternate_email_rounded,
              title: _lang == 'සිංහල'
                  ? 'විද්‍යුත් තැපෑල'
                  : _lang == 'தமிழ்'
                      ? 'மின்னஞ்சல்'
                      : 'Email Address',
              displayValue: _email,
              ctrl: null,
              editable: false,
            ),
            _infoTile(
              icon: Icons.phone_outlined,
              title: _lang == 'සිංහල'
                  ? 'දුරකථන අංකය'
                  : _lang == 'தமிழ்'
                      ? 'தொலைபேசி'
                      : 'Phone Number',
              displayValue: _phone.isEmpty
                  ? (_lang == 'සිංහල'
                      ? 'සකස් කර නැත'
                      : _lang == 'தமிழ்'
                          ? 'அமைக்கப்படவில்லை'
                          : 'Not set')
                  : _phone,
              ctrl: _phoneCtrl,
              editable: true,
            ),

            const SizedBox(height: 8),

            // ── PREFERENCES ────────────────────────────────────────────────
            _sectionHeader(
              _lang == 'සිංහල'
                  ? 'මනාප'
                  : _lang == 'தமிழ்'
                      ? 'விருப்பங்கள்'
                      : 'PREFERENCES',
            ),
            _actionTile(
              icon: Icons.language_rounded,
              title: _lang == 'සිංහල'
                  ? 'භාෂාව'
                  : _lang == 'தமிழ்'
                      ? 'மொழி'
                      : 'Language',
              trailing: _lang,
              color: null,
              onTap: _changeLanguage,
            ),

            const SizedBox(height: 8),

            // ── SECURITY ───────────────────────────────────────────────────
            _sectionHeader(
              _lang == 'සිංහල'
                  ? 'ආරක්ෂාව'
                  : _lang == 'தமிழ்'
                      ? 'பாதுகாப்பு'
                      : 'SECURITY',
            ),
            _actionTile(
              icon: Icons.lock_outline_rounded,
              title: _lang == 'සිංහල'
                  ? 'මුරපදය වෙනස් කරන්න'
                  : _lang == 'தமிழ்'
                      ? 'கடவுச்சொல் மாற்று'
                      : 'Change Password',
              color: null,
              onTap: () => Navigator.pushNamed(context, '/forgot-password'),
            ),

            const SizedBox(height: 8),

            // ── ACCOUNT ACTIONS ────────────────────────────────────────────
            _sectionHeader(
              _lang == 'සිංහල'
                  ? 'ගිණුම් ක්‍රියා'
                  : _lang == 'தமிழ்'
                      ? 'கணக்கு செயல்கள்'
                      : 'ACCOUNT ACTIONS',
            ),
            _actionTile(
              icon: Icons.logout_rounded,
              title: _lang == 'සිංහල'
                  ? 'ඉවත් වන්න'
                  : _lang == 'தமிழ்'
                      ? 'வெளியேறு'
                      : 'Log Out',
              color: null,
              onTap: _logout,
            ),
            _actionTile(
              icon: Icons.delete_forever_rounded,
              title: _lang == 'සිංහල'
                  ? 'ගිණුම මකන්න'
                  : _lang == 'தமிழ்'
                      ? 'கணக்கை நீக்கு'
                      : 'Delete Account',
              color: Colors.redAccent,
              onTap: _deleteAccount,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── WIDGETS ───────────────────────────────────────────────────────────────

  Widget _buildAvatarSection(String roleBadge) {
    return Column(
      children: [
        // Avatar ring
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00FF66), width: 2),
          ),
          child: const CircleAvatar(
            radius: 46,
            backgroundColor: Color(0xFF131A14),
            child: Icon(Icons.person, size: 48, color: Color(0xFF00FF66)),
          ),
        ),
        const SizedBox(height: 12),
        // Name
        Text(
          _name,
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        // Email sub-label
        Text(
          _email,
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
        const SizedBox(height: 8),
        // Role badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF00FF66).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF00FF66).withValues(alpha: 0.4)),
          ),
          child: Text(
            roleBadge,
            style: const TextStyle(
                color: Color(0xFF00FF66),
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              color: Colors.white38, fontSize: 11, letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String displayValue,
    required TextEditingController? ctrl,
    required bool editable,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF131A14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00FF66).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF00FF66), size: 18),
        ),
        title: Text(title,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        subtitle: ctrl != null && _isEditing && editable
            ? TextField(
                controller: ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(top: 4),
                ),
              )
            : Text(
                displayValue,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
        trailing: _isEditing && editable
            ? const Icon(Icons.edit, color: Color(0xFF00FF66), size: 16)
            : const Icon(Icons.chevron_right_rounded,
                color: Colors.white24, size: 18),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    Color? color,
    String? trailing,
    required VoidCallback onTap,
  }) {
    final c = color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF131A14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: c, size: 18),
          ),
          title: Text(title,
              style: TextStyle(
                  color: color ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          trailing: trailing != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(trailing,
                        style: const TextStyle(
                            color: Color(0xFF00FF66),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white24, size: 18),
                  ],
                )
              : const Icon(Icons.chevron_right_rounded,
                  color: Colors.white24, size: 18),
        ),
      ),
    );
  }
}
