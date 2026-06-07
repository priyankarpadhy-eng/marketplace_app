import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:market_app/models/post.dart';
import 'package:market_app/services/feed_service.dart';
import 'package:market_app/widgets/post_card.dart';
import 'package:market_app/models/app_user.dart';
import 'package:market_app/theme/app_theme.dart';
import 'package:market_app/widgets/guest_login_sheet.dart';
import 'package:market_app/screens/create_post_screen.dart';
import 'package:market_app/screens/conversations_screen.dart';
import 'package:market_app/screens/admin/admin_panel_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialHomeScreen extends StatefulWidget {
  final AppUser currentUser;

  const SocialHomeScreen({super.key, required this.currentUser});

  @override
  State<SocialHomeScreen> createState() => _SocialHomeScreenState();
}

class _SocialHomeScreenState extends State<SocialHomeScreen> {
  final FeedService _feedService = FeedService();
  String _activeTag = 'All';

  final List<String> _tags = ['All', 'Events', 'Discussion', 'Confession', 'Freelancing', 'Poetic', 'Help'];

  // Tag → icon mapping
  final Map<String, IconData> _tagIcons = {
    'All': Icons.all_inclusive_rounded,
    'Events': Icons.celebration_rounded,
    'Discussion': Icons.chat_bubble_rounded,
    'Confession': Icons.lock_rounded,
    'Freelancing': Icons.work_rounded,
    'Poetic': Icons.auto_awesome_rounded,
    'Help': Icons.handshake_rounded,
  };

  // Tag → color mapping
  Color _tagColor(String tag, bool isDark) {
    switch (tag) {
      case 'Events':      return const Color(0xFFEC4899);
      case 'Discussion':  return AppTheme.socialAccent;
      case 'Confession':  return Colors.purple;
      case 'Freelancing': return AppTheme.marketAccent;
      case 'Poetic':      return Colors.teal;
      case 'Help':        return AppTheme.rideAccent;
      default:            return AppTheme.accent(isDark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<dynamic>>(
        stream: _feedService.watchFeed(tag: _activeTag),
        initialData: _activeTag == 'All' ? FeedService.cachedFeed : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data ?? [];

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Premium Header ──────────────────────────────
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    pinned: true,
                    backgroundColor: AppTheme.surface(isDark),
                    expandedHeight: 74,
                    elevation: 0,
                    shape: Border(
                      bottom: BorderSide(
                        color: AppTheme.accent(isDark).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        color: AppTheme.surface(isDark),
                        padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo + brand
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accent(isDark),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const FaIcon(FontAwesomeIcons.fire, size: 10, color: Colors.white),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Social Feed',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: AppTheme.textSecondary(isDark),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getGreeting(),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: AppTheme.textPrimary(isDark),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Name + theme toggle
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.currentUser.name.split(' ')[0],
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary(isDark),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => themeProvider.toggleTheme(!isDark),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface(isDark),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppTheme.border(isDark)),
                                    ),
                                    child: Icon(
                                      isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                                      size: 14,
                                      color: isDark ? AppTheme.warning : AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Sticky Category Pill Filters ────────────────
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      minHeight: 62,
                      maxHeight: 62,
                      child: Container(
                        color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _tags.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final tag = _tags[index];
                            final selected = _activeTag == tag;
                            return GestureDetector(
                              onTap: () => setState(() => _activeTag = tag),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? (isDark ? AppTheme.primaryDark.withOpacity(0.15) : AppTheme.primarySoft)
                                      : AppTheme.surface(isDark),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: selected
                                        ? (isDark ? AppTheme.primaryDark : AppTheme.primary)
                                        : AppTheme.border(isDark),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _tagIcons[tag] ?? Icons.circle,
                                      size: 13,
                                      color: selected
                                          ? (isDark ? AppTheme.primaryDark : AppTheme.primary)
                                          : AppTheme.textSecondary(isDark),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      tag,
                                      style: GoogleFonts.roboto(
                                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                        fontSize: 12,
                                        color: selected
                                            ? (isDark ? AppTheme.primaryDark : AppTheme.primary)
                                            : AppTheme.textPrimary(isDark),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // ── WhatsApp Community Card ─────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: GestureDetector(
                        onTap: () => launchUrl(
                          Uri.parse('https://chat.whatsapp.com/D8gagbKfTZIC5JbCusG5dr'),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0D251A)
                                : AppTheme.successSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF25D366),
                                  shape: BoxShape.circle,
                                ),
                                child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Join Marketplace Group',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: isDark ? Colors.white : const Color(0xFF064E3B),
                                      ),
                                    ),
                                    Text(
                                      'Get real-time campus deal alerts',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : const Color(0xFF065F46).withOpacity(0.75),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: const Color(0xFF10B981), size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Feed List ───────────────────────────────────
                  if (posts.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.explore_off_rounded, size: 48, color: AppTheme.textSecondary(isDark)),
                            const SizedBox(height: 12),
                            Text('No vibes here yet', style: GoogleFonts.outfit(color: AppTheme.textSecondary(isDark), fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 150),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == posts.length) return _buildEndVibe(isDark);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PostCard(item: posts[index], currentUserId: widget.currentUser.id),
                            );
                          },
                          childCount: posts.length + 1,
                        ),
                      ),
                    ),
                ],
              ),

              // ── Create Post FAB ─────────────────────────────────
              Positioned(
                bottom: 125,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.accent(isDark),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        if (widget.currentUser.isGuest) {
                          GuestLoginSheet.show(context);
                          return;
                        }
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CreatePostScreen(currentUser: widget.currentUser)));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Icon(
                          Icons.add_rounded,
                          color: isDark ? AppTheme.darkBg : Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning ☀️';
    if (hour >= 12 && hour < 17) return 'Good Afternoon 🌤️';
    if (hour >= 17 && hour < 20) return 'Good Evening 🌇';
    return 'Good Night 🌙';
  }

  Widget _buildEndVibe(bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt(isDark),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 28, color: AppTheme.textSecondary(isDark)),
          ),
          const SizedBox(height: 12),
          Text(
            "You're all caught up!",
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textSecondary(isDark)),
          ),
          const SizedBox(height: 4),
          Text(
            "Check back later for more campus vibes.",
            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary(isDark)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({required this.minHeight, required this.maxHeight, required this.child});
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override double get minExtent => minHeight;
  @override double get maxExtent => math.max(maxHeight, minHeight);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_SliverAppBarDelegate old) =>
      maxHeight != old.maxHeight || minHeight != old.minHeight || child != old.child;
}
