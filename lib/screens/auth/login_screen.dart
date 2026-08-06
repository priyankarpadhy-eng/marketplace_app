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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Logo Frame (Matching Onboarding)
                Expanded(
                  flex: 5,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                      ],
                      border: isDark ? Border.all(color: Colors.white10) : Border.all(color: Colors.black12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
                        child: Transform.scale(
                          scale: 1.05, // Match onboarding zoom
                          child: Image.asset(
                            'assets/images/onboarding/login.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(Icons.image_outlined, size: 48, color: AppTheme.textSecondary(isDark)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Bottom Content Half
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Back",
                          style: GoogleFonts.syne(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.02,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Log in to connect with your campus community.",
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            height: 1.6,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const Spacer(),
                        
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
                          color: const Color(0xFF312E81), // Matching onboarding Next button
                          textColor: Colors.white,
                          onPressed: _loading ? null : _handleGoogleSignIn,
                        ),
                        
                        const SizedBox(height: 24),
                        
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
              ],
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
