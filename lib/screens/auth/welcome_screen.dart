import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Full-page background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Content overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 28, right: 28, bottom: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Error message
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: GoogleFonts.dmSans(
                                  color: Colors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Black Google Sign-in Button with colored icon
                    _buildGoogleButton(),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _loading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          shape: const StadiumBorder(
            side: BorderSide(
              color: Colors.white24,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_logo.png',
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

