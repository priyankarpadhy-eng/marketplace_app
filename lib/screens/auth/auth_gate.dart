import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/user_provider.dart';
import '../main_layout.dart';
import 'welcome_screen.dart';
import 'verify_email_screen.dart';
import 'whatsapp_phone_verification_screen.dart';
import '../splash_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    if (userState.isLoading) {
      return const SplashScreen();
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const WelcomeScreen();
    }

    if (!user.emailVerified && !user.isAnonymous) {
      return VerifyEmailScreen(user: user);
    }

    final currentUser = userState.currentUser!;
    final hasCompletedEitherVerification = currentUser.phoneVerified ||
        currentUser.isApprovedVerification ||
        currentUser.isPendingVerification;

    // User must do EITHER phone number verification OR student ID document upload
    if (!hasCompletedEitherVerification) {
      return WhatsAppPhoneVerificationScreen(currentUser: currentUser);
    }

    return MainLayout(currentUser: currentUser);
  }
}

