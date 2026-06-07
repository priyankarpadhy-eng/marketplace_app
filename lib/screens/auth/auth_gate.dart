import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../main_layout.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';
import '../splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoading) {
      return const SplashScreen();
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    if (!user.emailVerified && !user.isAnonymous) {
      return VerifyEmailScreen(user: user);
    }

    if (userProvider.currentUser == null) {
      return const SplashScreen();
    }

    return MainLayout(currentUser: userProvider.currentUser!);
  }
}
