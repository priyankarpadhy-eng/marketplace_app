import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:market_app/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Lottie.asset(
            'assets/catload.json',
            fit: BoxFit.contain,
            repeat: true,
          ),
        ),
      ),
    );
  }
}
