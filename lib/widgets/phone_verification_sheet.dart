import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:truecaller_sdk/truecaller_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class PhoneVerificationSheet extends StatefulWidget {
  final VoidCallback onVerified;

  const PhoneVerificationSheet({super.key, required this.onVerified});

  static Future<void> show(BuildContext context, {required VoidCallback onVerified}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PhoneVerificationSheet(onVerified: onVerified),
    );
  }

  @override
  State<PhoneVerificationSheet> createState() => _PhoneVerificationSheetState();
}

class _PhoneVerificationSheetState extends State<PhoneVerificationSheet> {
  StreamSubscription? _streamSubscription;
  bool _isTruecallerUsable = false;
  String? _codeVerifier;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initTruecaller();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initTruecaller() async {
    if (kIsWeb || !Platform.isAndroid) {
      if (mounted) {
        setState(() {
          _isTruecallerUsable = false;
          _isInitializing = false;
          _errorMessage = 'Truecaller is only supported on Android devices.';
        });
      }
      return;
    }

    try {
      final isUsable = await TcSdk.isOAuthFlowUsable;
      if (!isUsable) {
        if (mounted) {
          setState(() {
            _isTruecallerUsable = false;
            _isInitializing = false;
            _errorMessage = 'Truecaller app is not installed or configured on this device.';
          });
        }
        return;
      }

      // Generate verifier and challenge
      final verifier = await TcSdk.generateRandomCodeVerifier;
      if (verifier == null) {
        throw Exception('Failed to generate verifier');
      }

      final challenge = await TcSdk.generateCodeChallenge(verifier);
      if (challenge == null) {
        throw Exception('Failed to generate challenge');
      }

      await TcSdk.setCodeChallenge(challenge);
      _codeVerifier = verifier;

      // Set state and scopes
      await TcSdk.setOAuthState(DateTime.now().millisecondsSinceEpoch.toString());
      await TcSdk.setOAuthScopes(['profile', 'phone', 'openid']);

      // Setup Stream listener
      _streamSubscription = TcSdk.streamCallbackData.listen((event) async {
        debugPrint('TRUECALLER CALLBACK: result=${event.result}, error=${event.error?.message}');
        switch (event.result) {
          case TcSdkCallbackResult.success:
            final authCode = event.tcOAuthData?.authorizationCode;
            if (authCode != null && _codeVerifier != null) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
              }
              try {
                await AuthService.instance.verifyTruecaller(
                  authorizationCode: authCode,
                  codeVerifier: _codeVerifier!,
                );
                if (mounted) {
                  widget.onVerified();
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _errorMessage = e.toString().replaceFirst('Exception: ', '');
                    _isLoading = false;
                  });
                }
              }
            } else {
              if (mounted) {
                setState(() => _errorMessage = 'Verification code exchange failed.');
              }
            }
            break;
          case TcSdkCallbackResult.failure:
            if (mounted) {
              setState(() {
                _errorMessage = event.error?.message ?? 'Verification cancelled or failed.';
                _isLoading = false;
              });
            }
            break;
          default:
            break;
        }
      });

      if (mounted) {
        setState(() {
          _isTruecallerUsable = true;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTruecallerUsable = false;
          _isInitializing = false;
          _errorMessage = 'Initialization failed: $e';
        });
      }
    }
  }

  void _startVerification() async {
    if (!_isTruecallerUsable) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await TcSdk.getAuthorizationCode;
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to open Truecaller: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _mockVerify() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'phone_number': '+919999999999',
          'phone_verified': true,
        });
      }
      if (mounted) {
        widget.onVerified();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to mock verify: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 32,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.border(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            Text(
              'Verify phone',
              style: GoogleFonts.syne(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(isDark),
                letterSpacing: -0.02,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isTruecallerUsable
                  ? 'Verify your phone number instantly with 1-Tap using Truecaller.'
                  : 'Verify your phone number using Truecaller.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppTheme.textSecondary(isDark),
              ),
            ),
            const SizedBox(height: 24),
            
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppTheme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_isInitializing) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
              ),
            ] else ...[
              if (_isTruecallerUsable) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _startVerification,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.flash_on, size: 18),
                    label: Text(
                      _isLoading ? 'Verifying...' : '1-Tap Verification',
                      style: GoogleFonts.syne(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0087FF), // Truecaller signature brand color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
              
              if (kDebugMode || !_isTruecallerUsable) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _mockVerify,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.border(isDark)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Mock Verification (Development)',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary(isDark),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
