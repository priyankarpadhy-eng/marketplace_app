import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/marketplace_item.dart';
import '../services/marketplace_service.dart';
import '../widgets/listing_card.dart';
import '../models/app_user.dart';
import 'list_product_screen.dart';
import 'listing_detail_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'shop/shop_setup_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loader.dart';
import '../widgets/verification_modal.dart';

// â”€â”€ Design Tokens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const _kBg          = Color(0xFFF7F0FF);
const _kDark        = Color(0xFF1A1A2E);
const _kPrimary     = Color(0xFFA78BFA);
const _kLightPurple = Color(0xFFE9C8FF);
const _kYellow      = Color(0xFFF5D06E);
const _kMint        = Color(0xFFD1FAE5);
const _kBlush       = Color(0xFFFFE4E6);
const _kLavender    = Color(0xFFEDE9FE);
const _kLightYellow = Color(0xFFFEF3C7);
const _kGray        = Color(0xFF6B7280);

// Carousel gradient colours per slide index
const _kBannerGradients = [
  [Color(0xFFE8F0FE), Color(0xFFD2E3FC)],
  [Color(0xFFE6F4EA), Color(0xFFCEEAD6)],
  [Color(0xFFFEF7E0), Color(0xFFFEEFC3)],
  [Color(0xFFFCE8E6), Color(0xFFFAD2CF)],
  [Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
];

class MarketplaceScreen extends StatefulWidget {
  final AppUser currentUser;
  const MarketplaceScreen({super.key, required this.currentUser});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketplaceService _svc = MarketplaceService();
  final TextEditingController _searchCtrl = TextEditingController();

  // Data
  List<MarketplaceItem> _items = [];
  bool _loading = true;
  int _refreshesLeft = MarketplaceService.maxDailyRefreshes;
  StreamSubscription<List<MarketplaceItem>>? _realtimeSub;

  // Carousel
  final PageController _pageCtrl = PageController();
  int _carouselPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _startRealtimeUpdates();
    _loadData(force: false);
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _searchCtrl.dispose();
    _pageCtrl.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  // Real-time Firestore stream: picks up new listings automatically
  void _startRealtimeUpdates() {
    _realtimeSub?.cancel();
    _realtimeSub = _svc.getListingsStream().listen(
      (items) {
        if (!mounted) return;
        setState(() {
          _items = items;
          _loading = false;
        });
        _startCarouselTimer(items);
      },
      onError: (Object e) {
        print('Marketplace stream error: $e');
      },
    );
  }

  Future<void> _loadData({required bool force}) async {
    setState(() => _loading = _items.isEmpty);
    final items = await _svc.getListings(forceRefresh: force);
    final left  = await _svc.refreshesRemaining();
    if (mounted) {
      setState(() {
        _items = items;
        _refreshesLeft = left;
        _loading = false;
      });
      _startCarouselTimer(items);
    }
  }

  Future<void> _onRefresh() async {
    final allowed = await _svc.consumeRefresh();
    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Daily refresh limit reached (10/day). Resets tomorrow.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: _kDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }
    await _loadData(force: true);
  }

  void _startCarouselTimer(List<MarketplaceItem> items) {
    _autoScrollTimer?.cancel();
    final bannerCount = items.take(5).length;
    if (bannerCount < 2) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageCtrl.hasClients) return;
      final next = (_carouselPage + 1) % bannerCount;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _showComingSoon() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.rocket_launch_rounded, color: AppTheme.accent(isDark)),
            const SizedBox(width: 10),
            Text('Coming Soon', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
          ],
        ),
        content: Text(
          'We are working hard to bring this feature to you. Stay tuned!',
          style: GoogleFonts.roboto(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent(isDark)),
            child: Text('Got it', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // Apply search filter
  List<MarketplaceItem> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((i) =>
        i.title.toLowerCase().contains(q) ||
        i.description.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final cardColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textPrimary   = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final firstName = widget.currentUser.name.isNotEmpty ? widget.currentUser.name.split(' ').first : 'User';
    final filtered  = _filtered;
    final bannerItems = _items.take(5).toList();
    final listItems   = _searchCtrl.text.isEmpty && _items.length > 5
        ? _items.sublist(5)
        : filtered;

    final totalAvail = _items.where((i) => i.status == 'available').length;

    return Scaffold(
      backgroundColor: bgColor,

      // â”€â”€ FAB â€” Sell pill â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 95),
        child: GestureDetector(
          onTap: () async {
            AppUser activeUser = widget.currentUser;
            if (!activeUser.isDocumentVerified) {
              final updated = await showVerificationModal(context, currentUser: activeUser);
              if (updated != null) {
                activeUser = updated;
              }
            }
            
            if (!context.mounted) return;
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ListProductScreen(currentUser: activeUser),
            ));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.accent(isDark),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: isDark ? AppTheme.darkBg : Colors.white, size: 18),
                const SizedBox(width: 6),
                Text('Sell Item', style: GoogleFonts.roboto(color: isDark ? AppTheme.darkBg : Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),

      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _kPrimary,
          onRefresh: _onRefresh,
          child: _loading
              ? const AppLoader()
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
                  children: [

                    // ── Header ──────────────────────────────────────
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isDark ? AppTheme.darkSurfaceAlt : AppTheme.lightSurfaceAlt,
                          backgroundImage: widget.currentUser.profileImage != null
                              ? CachedNetworkImageProvider(widget.currentUser.profileImage!)
                              : null,
                          child: widget.currentUser.profileImage == null
                              ? Text(firstName[0].toUpperCase(),
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppTheme.accent(isDark), fontSize: 14))
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Hey, $firstName', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                            Text('Campus Marketplace', style: GoogleFonts.roboto(fontSize: 12, color: textSecondary)),
                          ]),
                        ),
                        // Refresh counter badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _refreshesLeft > 2
                                ? (isDark ? const Color(0xFF0F2E1E) : AppTheme.successSoft)
                                : (_refreshesLeft > 0
                                    ? (isDark ? const Color(0xFF3E2D0F) : const Color(0xFFFEF3C7))
                                    : (isDark ? const Color(0xFF3A1015) : const Color(0xFFFFE4E6))),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _refreshesLeft > 2
                                  ? AppTheme.success.withOpacity(0.2)
                                  : (_refreshesLeft > 0 ? AppTheme.warning.withOpacity(0.2) : AppTheme.error.withOpacity(0.2)),
                            ),
                          ),
                          child: Text(
                            '⟲ $_refreshesLeft',
                            style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ── Search bar ───────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.outfit(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Search products, items...',
                          hintStyle: GoogleFonts.outfit(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w400),
                          prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear_rounded, size: 18, color: textSecondary),
                                  onPressed: () => _searchCtrl.clear())
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // â”€â”€ Hero Carousel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (bannerItems.isNotEmpty && _searchCtrl.text.isEmpty) ...[
                      _HeroCarousel(
                        items: bannerItems,
                        pageCtrl: _pageCtrl,
                        currentPage: _carouselPage,
                        onPageChanged: (p) => setState(() => _carouselPage = p),
                        onTap: (item) => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ListingDetailScreen(item: item),
                        )),
                      ),
                      const SizedBox(height: 20),

                      // â”€â”€ Stat Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      Row(children: [
                        _StatCard(icon: Icons.grid_view_rounded, count: '${_items.length}', label: 'Total',     accentColor: AppTheme.accent(isDark), isDark: isDark, onTap: null),
                        const SizedBox(width: 10),
                        _StatCard(icon: Icons.check_circle_outline_rounded, count: '$totalAvail', label: 'Available', accentColor: AppTheme.success, isDark: isDark, onTap: null),
                      ]),
                      const SizedBox(height: 20),
                    ],

                    // â”€â”€ Section header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _searchCtrl.text.isEmpty ? 'All Listings' : 'Results',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                        Text('See All', style: GoogleFonts.poppins(fontSize: 13, color: _kPrimary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // â”€â”€ Listing grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    if (listItems.isEmpty)
                      Center(
                        child: Column(children: [
                          const SizedBox(height: 40),
                          const Icon(Icons.search_off_rounded, size: 52, color: Color(0xFF9CA3AF)),
                          const SizedBox(height: 10),
                          Text('No items found', style: GoogleFonts.poppins(color: _kGray, fontSize: 15)),
                        ]),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: listItems.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemBuilder: (context, i) => ListingCard(
                          item: listItems[i],
                          index: i,
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ListingDetailScreen(item: listItems[i]),
                          )),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  Hero Carousel â€” auto-sliding PageView with dot indicators
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _HeroCarousel extends StatelessWidget {
  final List<MarketplaceItem> items;
  final PageController pageCtrl;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<MarketplaceItem> onTap;

  const _HeroCarousel({
    required this.items,
    required this.pageCtrl,
    required this.currentPage,
    required this.onPageChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: pageCtrl,
            itemCount: items.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, i) {
              final item = items[i];
              final gradient = _kBannerGradients[i % _kBannerGradients.length];
              return GestureDetector(
                onTap: () => onTap(item),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Left text
                      Positioned(
                        top: 0, left: 0, bottom: 0, right: 130,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item.category, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(color: const Color(0xFF111111).withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(color: const Color(0xFF111111), fontSize: 16, fontWeight: FontWeight.w800, height: 1.2)),
                              const SizedBox(height: 2),
                              Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(color: const Color(0xFF111111).withValues(alpha: 0.8), fontSize: 11, height: 1.3)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(color: _kDark, borderRadius: BorderRadius.circular(20)),
                                child: Text('₹${item.price.toStringAsFixed(0)}  >',
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Right image
                      Positioned(
                        right: 0, top: 0, bottom: 0, width: 135,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          child: item.images.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: item.images.first,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: Colors.white12, child: const Icon(Icons.image_rounded, color: Colors.white38, size: 40)),
                                  errorWidget: (_, __, ___) => Container(color: Colors.white12, child: const Icon(Icons.storefront_rounded, color: Colors.white38, size: 40)),
                                )
                              : Container(color: Colors.white12, child: const Icon(Icons.storefront_rounded, color: Colors.white38, size: 40)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Dot indicators
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (i) {
            final active = i == currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? _kPrimary : _kPrimary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// â”€â”€ Stat Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color accentColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCard({required this.icon, required this.count, required this.label, required this.accentColor, this.isDark = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final subColor  = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: AppTheme.surface(isDark), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border(isDark), width: 1)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 16, color: accentColor),
                  Icon(Icons.arrow_outward_rounded, size: 13, color: subColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(count, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, height: 1.1)),
              Text(label, style: GoogleFonts.roboto(fontSize: 10, color: subColor)),
            ],
          ),
        ),
      ),
    );
  }
}


