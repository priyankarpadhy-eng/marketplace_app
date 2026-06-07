import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:market_app/models/app_user.dart';
import 'package:market_app/services/deep_link_service.dart';
import 'package:market_app/services/notification_service.dart';
import 'package:market_app/theme/app_theme.dart';

import 'package:market_app/screens/social_home_screen.dart';
import 'package:market_app/screens/marketplace_screen.dart';
import 'package:market_app/screens/ride_feed_screen.dart';
import 'package:market_app/screens/profile_screen.dart';


const _kItems = [
  _NavItem(icon: FontAwesomeIcons.house,       label: 'Home'),
  _NavItem(icon: FontAwesomeIcons.carSide,     label: 'Rides'),
  _NavItem(icon: FontAwesomeIcons.bagShopping, label: 'Market'),
  _NavItem(icon: FontAwesomeIcons.solidUser,   label: 'Me'),
];


// ════════════════════════════════════════════════════════════════════
class MainLayout extends StatefulWidget {
  final AppUser currentUser;
  final int initialIndex;

  const MainLayout({super.key, required this.currentUser, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _pageIndex;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.init(context);
      NotificationService.instance.setupPushNotifications(widget.currentUser.id);
    });
  }

  @override
  void dispose() {
    DeepLinkService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      SocialHomeScreen(currentUser: widget.currentUser),
      RideFeedScreen(currentUser: widget.currentUser),
      MarketplaceScreen(currentUser: widget.currentUser),
      ProfileScreen(currentUser: widget.currentUser),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Container(
        color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        child: IndexedStack(
          index: _pageIndex.clamp(0, pages.length - 1),
          children: pages,
        ),
      ),
      bottomNavigationBar: _NavBar(
        currentIndex: _pageIndex,
        isDark: isDark,
        onTap: (i) => setState(() => _pageIndex = i),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  Simple, Fast, and Premium Docked Bottom Navbar
// ════════════════════════════════════════════════════════════════════
class _NavBar extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _NavBar({
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppTheme.surface(isDark);
    final borderColor = AppTheme.border(isDark);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor.withOpacity(isDark ? 0.85 : 0.90),
            border: Border(
              top: BorderSide(
                color: borderColor.withOpacity(isDark ? 0.4 : 0.6),
                width: 0.8,
              ),
            ),
          ),
          child: SafeArea(
            bottom: true,
            top: false,
            child: SizedBox(
              height: 58,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  _kItems.length,
                  (i) => Expanded(
                    child: InkWell(
                      onTap: () => onTap(i),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: _NavButton(
                        item: _kItems[i],
                        selected: i == currentIndex,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Simple, snappy nav button ────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final bool isDark;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.accent(isDark);
    final inactiveColor = AppTheme.textSecondary(isDark);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedScale(
          scale: selected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: FaIcon(
            item.icon,
            size: 20,
            color: selected ? activeColor : inactiveColor,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? activeColor : inactiveColor,
          ),
          child: Text(item.label),
        ),
      ],
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
