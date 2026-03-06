import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  final String lang;
  const SignupScreen({super.key, this.lang = 'English'});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  // Enthusiast specific controllers
  final _phoneController = TextEditingController();
  final _orgController = TextEditingController();
  final _expController = TextEditingController();

  String _selectedRole = 'user';
  bool _isLoading = false;
  bool _obscure = true;
  bool _shareLocation = true;

  // Localization helper
  String _t(String key) => LanguageService.t(widget.lang, key);

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final res = await _auth.sendOTP(_emailController.text.trim());

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res['success']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              userData: {
                'fname': _nameController.text.trim(),
                'email': _emailController.text.trim(),
                'password': _passController.text.trim(),
                'role': _selectedRole,
                if (_selectedRole == 'enthusiast') ...{
                  'phone': _phoneController.text.trim(),
                  'org': _orgController.text.trim(),
                  'exp': _expController.text.trim(),
                  'share_location': _shareLocation.toString(),
                }
              },
              lang: widget.lang,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('error_network')),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.asset('assets/images/nexor.png',
                  height: 100,
                  errorBuilder: (c, e, s) => const Icon(Icons.bug_report,
                      color: Color(0xFF00FF66), size: 50)),

              const SizedBox(height: 25),
              Text(_t('create_account'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(_t('signup_subtitle'),
                  style: const TextStyle(color: Colors.white38, fontSize: 16),
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),

              // ROLE SELECTION
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_t('i_am_a'),
                    style: const TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _roleBtn(_t('general_public'), _selectedRole == 'user',
                      () => setState(() => _selectedRole = 'user')),
                  const SizedBox(width: 10),
                  _roleBtn(
                      _t('snake_enthusiast'),
                      _selectedRole == 'enthusiast',
                      () => setState(() => _selectedRole = 'enthusiast')),
                ],
              ),

              const SizedBox(height: 35),

              _label(_t('full_name')),
              _field(_nameController, _t('name_hint'), Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? _t('name_required') : null),

              const SizedBox(height: 20),

              _label(_t('email')),
              _field(_emailController, 'example@mail.com', Icons.email_outlined,
                  validator: (v) => (v != null && !v.contains('@'))
                      ? _t('email_invalid')
                      : null),

              const SizedBox(height: 20),

              _label(_t('password')),
              _field(
                _passController,
                _t('pass_min'),
                Icons.lock_outline,
                isPass: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return _t('pass_short');
                  final hasMinLength = v.length >= 8;
                  final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
                  final hasLower = RegExp(r'[a-z]').hasMatch(v);
                  final hasNumber = RegExp(r'[0-9]').hasMatch(v);
                  if (!hasMinLength || !hasUpper || !hasLower || !hasNumber) {
                    return _t('pass_complex');
                  }
                  return null;
                },
              ),

              if (_selectedRole == 'enthusiast') ...[
                const SizedBox(height: 30),
                const Divider(color: Colors.white10),
                const SizedBox(height: 20),
                const Text('Expert Details',
                    style: TextStyle(
                        color: Color(0xFF00FF66),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _label('Contact Number (Required)'),
                _field(
                    _phoneController, 'e.g. 0771234567', Icons.phone_outlined,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Phone number is required for dispatch'
                        : null),
                const SizedBox(height: 20),
                _label('Organization / Affiliation (Optional)'),
                _field(_orgController, 'e.g. Wildlife Rescue Team',
                    Icons.business_outlined),
                const SizedBox(height: 20),
                _label('Years of Experience'),
                _field(_expController, 'e.g. 5', Icons.timer_outlined,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Experience needed for verification'
                        : null),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Switch(
                      value: _shareLocation,
                      onChanged: (v) => setState(() => _shareLocation = v),
                      activeColor: const Color(0xFF00FF66),
                    ),
                    const Expanded(
                      child: Text(
                        'Enable Location Sharing\n(Required to receive rescue requests near you)',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF66),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _handleSignup,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(_t('get_code'),
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_t('already_account'),
                      style: const TextStyle(color: Colors.white38)),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(_t('log_in'),
                        style: const TextStyle(
                            color: Color(0xFF00FF66),
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleBtn(String t, bool s, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: s ? const Color(0xFF132A1C) : const Color(0xFF1A1F1B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: s ? const Color(0xFF00FF66) : Colors.transparent),
            ),
            child: Center(
                child: Text(t,
                    style: TextStyle(
                        color: s ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center)),
          ),
        ),
      );

  Widget _label(String text) => Align(
      alignment: Alignment.centerLeft,
      child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15))));

  Widget _field(TextEditingController c, String h, IconData i,
          {bool isPass = false, String? Function(String?)? validator}) =>
      TextFormField(
        controller: c,
        obscureText: isPass ? _obscure : false,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: h,
          hintStyle: const TextStyle(color: Colors.white10),
          prefixIcon: Icon(i, color: Colors.white38, size: 20),
          suffixIcon: isPass
              ? IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white38),
                  onPressed: () => setState(() => _obscure = !_obscure))
              : null,
          filled: true,
          fillColor: const Color(0xFF1A1F1B),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00FF66))),
          errorStyle: const TextStyle(color: Colors.redAccent),
        ),
      );
}
