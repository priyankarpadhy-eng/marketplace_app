import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _agreeToTerms = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to the Terms & Privacy Policy')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nickname: _nicknameController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification link sent to your email.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Create Account",
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
                ),
                Text(
                  "Join the community",
                  style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_error != null)
                           Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                          ),
                        
                        _buildField(
                          controller: _nicknameController,
                          label: "Username / Nickname",
                          icon: Icons.alternate_email_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _emailController,
                          label: "Email",
                          icon: Icons.email_outlined,
                          type: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _passwordController,
                          label: "Password",
                          icon: Icons.lock_outline_rounded,
                          isPass: true,
                          obscure: _obscurePass,
                          onToggle: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _confirmController,
                          label: "Confirm Password",
                          icon: Icons.lock_reset_rounded,
                          isPass: true,
                          obscure: _obscureConfirm,
                          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          validator: (v) => v != _passwordController.text ? "Passwords match fail" : null,
                        ),
                        
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              onChanged: (v) => setState(() => _agreeToTerms = v!),
                              activeColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            Expanded(
                              child: Wrap(
                                children: [
                                  Text("I agree to the ", style: GoogleFonts.outfit(fontSize: 12)),
                                  _linkText("Terms of Service", "https://igitmarketplace.vercel.app/terms"),
                                  Text(" & ", style: GoogleFonts.outfit(fontSize: 12)),
                                  _linkText("Privacy Policy", "https://igitmarketplace.vercel.app/privacy"),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _loading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : Text("CREATE ACCOUNT", style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPass = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      validator: validator ?? (v) => v!.isEmpty ? "Required" : null,
      style: GoogleFonts.outfit(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.primary),
        suffixIcon: isPass ? IconButton(onPressed: onToggle, icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18)) : null,
        filled: true,
        fillColor: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        labelStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
      ),
    );
  }

  Widget _linkText(String text, String url) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url)),
      child: Text(
        text,
        style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
      ),
    );
  }
}
