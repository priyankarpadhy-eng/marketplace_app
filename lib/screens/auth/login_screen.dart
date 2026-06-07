import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleGuestSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signInAnonymously();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
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
      body: Stack(
        children: [
          // Background Gradient Blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(isDark ? 0.1 : 0.2),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo & Branding
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset('assets/logo.png', height: 80, errorBuilder: (_, __, ___) => const Icon(Icons.hub_rounded, size: 80, color: AppTheme.primary)),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "Marketplace",
                        style: GoogleFonts.outfit(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        "Campus. Connection. Community.",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Selection Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                              blurRadius: 40,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_error != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _error!, 
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            // Google Sign In
                            _buildLoginButton(
                              label: "Continue with Google",
                              icon: FontAwesomeIcons.google,
                              color: AppTheme.primary,
                              textColor: Colors.black,
                              onPressed: _loading ? null : _handleGoogleSignIn,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Guest Sign In
                            _buildLoginButton(
                              label: "Continue as Guest",
                              icon: Icons.person_outline_rounded,
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                              textColor: isDark ? Colors.white : Colors.black87,
                              onPressed: _loading ? null : _handleGuestSignIn,
                              isOutlined: true,
                            ),
                            
                            const SizedBox(height: 24),
                            Text(
                              "By joining, you agree to our terms.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),
                      // Links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLink("Privacy Policy", "https://igitmarketplace.vercel.app/privacy"),
                          const Text(" • ", style: TextStyle(color: Colors.grey)),
                          _buildLink("Terms of Service", "https://igitmarketplace.vercel.app/terms"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback? onPressed,
    bool isOutlined = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isOutlined ? BorderSide(color: Colors.grey.withOpacity(0.2)) : BorderSide.none,
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLink(String text, String url) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView),
      child: Text(
        text,
        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, decoration: TextDecoration.underline),
      ),
    );
  }
}
