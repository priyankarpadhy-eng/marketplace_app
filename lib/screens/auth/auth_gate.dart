import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/user_provider.dart';
import '../main_layout.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';
import '../splash_screen.dart';
import '../auth/onboarding_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _hasSeenOnboarding = false;
  bool _onboardingChecked = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = false; // Temporarily forced to false so you can see the new design
    if (mounted) {
      setState(() {
        _hasSeenOnboarding = hasSeen;
        _onboardingChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    if (userState.isLoading || !_onboardingChecked) {
      return const SplashScreen();
    }

    if (!_hasSeenOnboarding) {
      return OnboardingScreen(
        markOnboardingSeen: () {
          if (mounted) {
            setState(() {
              _hasSeenOnboarding = true;
            });
          }
        },
      );
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    if (!user.emailVerified && !user.isAnonymous) {
      return VerifyEmailScreen(user: user);
    }

    if (userState.currentUser == null) {
      return const SplashScreen();
    }

    return MainLayout(currentUser: userState.currentUser!);
  }
}
