import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:market_app/models/app_user.dart';
import 'package:market_app/services/deep_link_service.dart';
import 'package:market_app/services/notification_service.dart';
import 'package:market_app/theme/app_theme.dart';

import 'package:market_app/screens/ride_feed_screen.dart';
import 'package:market_app/screens/campus_radar_screen.dart';
import 'package:market_app/screens/profile_screen.dart';
import 'package:market_app/providers/user_provider.dart';

import 'package:market_app/widgets/mini_player.dart';
import 'package:google_nav_bar/google_nav_bar.dart';


import 'package:shared_preferences/shared_preferences.dart';
import 'package:market_app/widgets/verification_modal.dart';

// ════════════════════════════════════════════════════════════════════
class MainLayout extends ConsumerStatefulWidget {
  final AppUser currentUser;
  final int initialIndex;

  const MainLayout({super.key, required this.currentUser, this.initialIndex = 0});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  late int _pageIndex;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.init(context, ref);
      NotificationService.instance.setupPushNotifications(widget.currentUser.id);
      _checkVerificationPrompt();
    });
  }

  Future<void> _checkVerificationPrompt() async {
    if (widget.currentUser.isDocumentVerified) return;
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenVerificationPrompt_${widget.currentUser.id}') ?? false;
    if (!hasSeen && mounted) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        final updated = await showVerificationModal(context, currentUser: widget.currentUser);
        if (updated != null && mounted) {
          ref.read(userProvider.notifier).refreshUser();
        }
      }
    }
  }

  @override
  void dispose() {
    DeepLinkService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userState = ref.watch(userProvider);
    final currentUser = userState.currentUser ?? widget.currentUser;

    final List<Widget> pages = [
      RideFeedScreen(currentUser: currentUser),
      CampusRadarScreen(currentUser: currentUser),
      ProfileScreen(currentUser: currentUser),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Container(
        color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        child: Stack(
          children: [
            IndexedStack(
              index: _pageIndex.clamp(0, pages.length - 1),
              children: pages,
            ),
            
            // Global Mini Player
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 70, // Avoid overlapping the 58px navbar
              child: const GlobalMiniPlayer(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16, top: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: isDark ? Colors.white30 : Colors.grey[300]!,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1C1C1E).withValues(alpha: 0.55)
                          : Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                      child: GNav(
                        gap: 8,
                        activeColor: isDark ? Colors.white : Colors.black87,
                        iconSize: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        duration: const Duration(milliseconds: 300),
                        tabBackgroundColor: isDark ? Colors.white12 : Colors.grey[200]!, // Adapts to theme
                        color: isDark ? Colors.white54 : Colors.black54,
                        textStyle: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        tabs: const [
                          GButton(
                            icon: FontAwesomeIcons.carSide,
                            iconSize: 24,
                          ),
                          GButton(
                            icon: Icons.radar_rounded,
                            iconSize: 29, // Enlarged to match FontAwesome visual weight
                          ),
                          GButton(
                            icon: FontAwesomeIcons.solidUser,
                            iconSize: 24,
                          ),
                        ],
                        selectedIndex: _pageIndex,
                        onTabChange: (index) {
                          setState(() {
                            _pageIndex = index;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
