import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:market_app/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_app/theme/app_theme.dart';
import 'package:market_app/screens/auth/auth_gate.dart';
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
      home: const AuthGate(),
    );
  }
}
