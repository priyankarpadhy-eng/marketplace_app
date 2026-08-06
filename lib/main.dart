import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:market_app/services/notification_service.dart';
import 'package:market_app/providers/user_provider.dart';
import 'package:market_app/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_app/theme/app_theme.dart';
import 'package:market_app/screens/main_layout.dart';
import 'package:market_app/models/app_user.dart';
import 'package:market_app/screens/auth/login_screen.dart';
import 'package:market_app/screens/auth/onboarding_screen.dart';
import 'package:market_app/screens/restaurant/restaurant_root_screen.dart';
import 'firebase_options.dart';

import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");

    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.market.app.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    await NotificationService.instance.init().catchError((e) {
      debugPrint("Notification init error: $e");
      return null;
    });
    
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e) {
    debugPrint("CRITICAL BOOT ERROR: $e");
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text("Boot Error: $e")))));
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Marketplace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenOnboarding') ?? false;
    if (mounted) {
      setState(() {
        _showOnboarding = !hasSeen;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    }

    if (_showOnboarding) {
      return OnboardingScreen(
        markOnboardingSeen: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasSeenOnboarding', true);
          if (mounted) {
            setState(() {
              _showOnboarding = false;
            });
          }
        },
      );
    }

    return StreamBuilder(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "IGIT MARKETPLACE",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return FutureBuilder<AppUser?>(
          future: AuthService.instance.getCurrentAppUser(),
          builder: (context, userSnapshot) {
            if (userSnapshot.hasData && userSnapshot.data != null) {
              final user = userSnapshot.data!;
              if (user.isRestaurant) {
                return RestaurantRootScreen(currentUser: user);
              }
              return MainLayout(currentUser: user);
            }
            return const LoginScreen();
          },
        );
      },
    );
  }
}
