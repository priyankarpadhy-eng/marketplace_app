import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final User user;

  const VerifyEmailScreen({super.key, required this.user});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _sending = false;
  bool _checking = false;
  String? _message;

  Future<void> _sendEmail() async {
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await widget.user.sendEmailVerification();
      setState(() {
        _message = 'Verification email sent. Check your inbox.';
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to send email: $e';
      });
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }

  Future<void> _checkVerified() async {
    setState(() {
      _checking = true;
      _message = null;
    });
    try {
      await widget.user.reload();
      final refreshed =
          FirebaseAuth.instance.currentUser;
      if (refreshed != null && refreshed.emailVerified) {
        setState(() {
          _message = 'Email verified. You can continue.';
        });
      } else {
        setState(() {
          _message = 'Not verified yet. Refresh after you click the link.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Failed to check status: $e';
      });
    } finally {
      setState(() {
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify email'),
        actions: [
          IconButton(
            onPressed: () => AuthService.instance.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Confirm your email',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a verification link to:\n'
                    '${widget.user.email ?? ''}\n\n'
                    'Open the link in your email, then tap "I\'ve verified" '
                    'below to continue.',
                  ),
                  const SizedBox(height: 16),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _message!,
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _sending ? null : _sendEmail,
                    child: _sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                            ),
                          )
                        : const Text('Resend verification email'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _checking ? null : _checkVerified,
                    child: _checking
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('I\'ve verified'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

