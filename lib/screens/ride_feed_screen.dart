import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/ride.dart';
import '../services/ride_service.dart';
import '../widgets/ride_card.dart';
import 'create_ride_screen.dart';
import 'ride_detail_screen.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../widgets/guest_login_sheet.dart';
import '../widgets/ride_how_it_works_card.dart';

class RideFeedScreen extends StatefulWidget {
  final AppUser currentUser;

  const RideFeedScreen({super.key, required this.currentUser});

  @override
  State<RideFeedScreen> createState() => _RideFeedScreenState();
}

class _RideFeedScreenState extends State<RideFeedScreen> {
  final RideService _rideService = RideService();
  final TextEditingController _searchController = TextEditingController();
  String _genderFilter = 'all';
  late Stream<List<Ride>> _ridesStream;
  String _selectedTab = 'active'; // 'active' or 'past'

  @override
  void initState() {
    super.initState();
    _ridesStream = _rideService.watchAllRides();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [AppTheme.rideAccent.withOpacity(0.9), AppTheme.rideAccent]
                  : [AppTheme.rideAccent, const Color(0xFFD97706)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.rideAccent.withOpacity(0.4),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (widget.currentUser.isGuest) {
                  GuestLoginSheet.show(context);
                  return;
                }
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CreateRideScreen(currentUser: widget.currentUser),
                ));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(FontAwesomeIcons.carSide, size: 15, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'OFFER RIDE',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Ride>>(
        stream: _ridesStream,
        initialData: RideService.cachedRides,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading rides: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final data = snapshot.data ?? [];
          final filtered = _applyFilters(data);
          final now = DateTime.now();

          final activeRides = filtered
              .where((r) => r.status == 'active' && r.departureTime.add(const Duration(minutes: 30)).isAfter(now))
              .toList()
            ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

          final pastRides = filtered
              .where((r) => r.status != 'active' || r.departureTime.add(const Duration(minutes: 30)).isBefore(now))
              .toList()
            ..sort((a, b) => b.departureTime.compareTo(a.departureTime));

          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              physics: const BouncingScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                // ── Branded Header ──────────────────────────────────
                SliverAppBar(
                  floating: true,
                  snap: true,
                  pinned: true,
                  backgroundColor: AppTheme.surface(isDark),
                  expandedHeight: 80,
                  elevation: 0,
                  shape: Border(
                    bottom: BorderSide(
                      color: AppTheme.rideAccent.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 38, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon badge
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.rideAccent, Color(0xFFD97706)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const FaIcon(FontAwesomeIcons.carSide, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Ride Sharing',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary(isDark),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Rides',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    color: AppTheme.textPrimary(isDark),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // How it works button
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (context) => const _RideHowItWorksBottomSheet(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.surface(isDark),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.rideAccent.withOpacity(0.5), width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 12, color: AppTheme.rideAccent),
                                  const SizedBox(width: 4),
                                  Text(
                                    'How it works?',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.rideAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Gender Filter Chips ─────────────────────────────
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        _RideFilterChip(label: 'All',         icon: FontAwesomeIcons.layerGroup,    value: 'all',    groupValue: _genderFilter, color: AppTheme.rideAccent,        onSelected: (v) => setState(() => _genderFilter = v)),
                        _RideFilterChip(label: 'Mixed',       icon: FontAwesomeIcons.users,         value: 'mixed',  groupValue: _genderFilter, color: AppTheme.rideAccent,        onSelected: (v) => setState(() => _genderFilter = v)),
                        _RideFilterChip(label: 'Female Only', icon: FontAwesomeIcons.personDress,   value: 'female', groupValue: _genderFilter, color: const Color(0xFFEC4899),    onSelected: (v) => setState(() => _genderFilter = v)),
                        _RideFilterChip(label: 'Male Only',   icon: FontAwesomeIcons.person,        value: 'male',   groupValue: _genderFilter, color: const Color(0xFF3B82F6),    onSelected: (v) => setState(() => _genderFilter = v)),
                      ],
                    ),
                  ),
                ),

                // ── Search Bar ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface(isDark),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border(isDark)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() {}),
                        style: GoogleFonts.roboto(fontSize: 13, color: AppTheme.textPrimary(isDark)),
                        decoration: InputDecoration(
                          hintText: 'Search by location, destination or Ride #...',
                          hintStyle: GoogleFonts.roboto(color: AppTheme.textSecondary(isDark), fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary(isDark), size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear_rounded, size: 18, color: AppTheme.textSecondary(isDark)),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Ride Segmented Tabs ─────────────────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    Container(
                      color: AppTheme.scaffoldBg(isDark),
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.surface(isDark),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.rideAccent.withOpacity(0.4), width: 1.5),
                        ),
                        child: TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppTheme.rideAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: AppTheme.textSecondary(isDark),
                          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Current & Future'),
                            Tab(text: 'Past Rides'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              
              // ── Ride List (TabBarView) ────────────────────────────
              body: TabBarView(
                children: [
                  // Active Rides Tab
                  activeRides.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.rideAccent.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const FaIcon(FontAwesomeIcons.car, size: 40, color: AppTheme.rideAccent),
                              ),
                              const SizedBox(height: 16),
                              Text('No active rides found', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(isDark))),
                              const SizedBox(height: 4),
                              Text('Be the first to offer a ride!', style: GoogleFonts.outfit(color: AppTheme.textSecondary(isDark))),
                              const SizedBox(height: 120),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 120),
                          itemCount: activeRides.length,
                          itemBuilder: (context, index) {
                            final ride = activeRides[index];
                            return RideCard(
                              ride: ride,
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => RideDetailScreen(ride: ride, currentUser: widget.currentUser),
                              )),
                            );
                          },
                        ),
                  
                  // Past Rides Tab
                  pastRides.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.textSecondary(isDark).withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: FaIcon(FontAwesomeIcons.clockRotateLeft, size: 40, color: AppTheme.textSecondary(isDark)),
                              ),
                              const SizedBox(height: 16),
                              Text('No past rides found', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(isDark))),
                              const SizedBox(height: 120),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 120),
                          itemCount: pastRides.length,
                          itemBuilder: (context, index) {
                            final ride = pastRides[index];
                            return Opacity(
                              opacity: 0.75,
                              child: RideCard(
                                ride: ride,
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => RideDetailScreen(ride: ride, currentUser: widget.currentUser),
                                )),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Ride> _applyFilters(List<Ride> rides) {
    final query = _searchController.text.trim().toLowerCase();
    return rides.where((ride) {
      final matchesSearch = query.isEmpty ||
          ride.from.toLowerCase().contains(query) ||
          ride.to.toLowerCase().contains(query) ||
          (ride.rideNumber != null && ride.rideNumber!.contains(query));
      final matchesGender = _genderFilter == 'all' || ride.genderPreference == _genderFilter;
      return matchesSearch && matchesGender;
    }).toList();
  }
}

// ── Filter Chip Widget ─────────────────────────────────────────
class _RideFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String groupValue;
  final Color color;
  final ValueChanged<String> onSelected;

  const _RideFilterChip({
    required this.label, required this.icon, required this.value,
    required this.groupValue, required this.color, required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : AppTheme.surface(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppTheme.border(isDark),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 11, color: selected ? Colors.white : color),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : AppTheme.textPrimary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideHowItWorksBottomSheet extends StatelessWidget {
  const _RideHowItWorksBottomSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How Ride Sharing Works',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            const RideHowItWorksCard(),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget _child;

  _SliverAppBarDelegate(this._child);

  @override
  double get minExtent => 52.0;
  @override
  double get maxExtent => 52.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return oldDelegate._child != _child;
  }
}
