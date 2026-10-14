import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../models/app_user.dart';
import '../models/campus_hub_presence.dart';
import '../services/campus_radar_service.dart';
import '../theme/app_theme.dart';
import '../widgets/id_card_dialog.dart';
import '../widgets/verification_badge.dart';

enum RadarViewMode { split, fullMap, listOnly }

class CampusRadarScreen extends StatefulWidget {
  final AppUser currentUser;
  final bool showBackButton;

  const CampusRadarScreen({
    super.key,
    required this.currentUser,
    this.showBackButton = false,
  });

  @override
  State<CampusRadarScreen> createState() => _CampusRadarScreenState();
}

class _CampusRadarScreenState extends State<CampusRadarScreen> {
  final CampusRadarService _radarService = CampusRadarService.instance;
  final MapController _mapController = MapController();

  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _permissionDenied = false;
  String? _errorMessage;
  RadarViewMode _viewMode = RadarViewMode.split;
  CampusHubPresence? _selectedPresence;

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocation();
  }

  Future<void> _checkAndRequestLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          _errorMessage =
              'Location services are disabled on your device. Please turn on GPS.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            _permissionDenied = true;
            _errorMessage =
                'Location permission is required to spot active students near you.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _permissionDenied = true;
          _errorMessage =
              'Location permission is permanently denied. Please enable it in Settings.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      _currentPosition = position;
      _permissionDenied = false;

      // Broadcast user presence automatically with exact coordinates
      await _radarService.broadcastLocation(
        user: widget.currentUser,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        _centerMapOnUser();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _errorMessage = 'Unable to get location: $e';
        });
      }
    }
  }

  void _centerMapOnUser() {
    if (_currentPosition != null) {
      try {
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          14.5,
        );
      } catch (_) {}
    }
  }

  void _centerMapOnPresence(CampusHubPresence presence) {
    if (presence.latitude != null && presence.longitude != null) {
      try {
        _mapController.move(
          LatLng(presence.latitude!, presence.longitude!),
          15.5,
        );
      } catch (_) {}
    }
  }

  Future<void> _leaveRadar() async {
    await _radarService.checkOut(widget.currentUser.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are now offline.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (widget.showBackButton && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _launchCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    var clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 10) clean = '91$clean';
    final uri = Uri.parse(
        'https://wa.me/$clean?text=${Uri.encodeComponent("Hi, I saw you nearby on the IGIT Campus Radar.")}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
        titleSpacing: (widget.showBackButton && Navigator.of(context).canPop()) ? 0 : 16,
        automaticallyImplyLeading: false,
        leading: (widget.showBackButton && Navigator.of(context).canPop())
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.radar_rounded, size: 17, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Radar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.syne(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Active in last 20 mins',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(fontSize: 11, color: textSecondary),
            ),
          ],
        ),
        actions: [
          // View Mode Selector
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131D31) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.splitscreen_rounded,
                    size: 16,
                    color: _viewMode == RadarViewMode.split
                        ? AppTheme.rideAccent
                        : textSecondary,
                  ),
                  tooltip: 'Split View',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _viewMode = RadarViewMode.split),
                ),
                IconButton(
                  icon: Icon(
                    Icons.map_outlined,
                    size: 16,
                    color: _viewMode == RadarViewMode.fullMap
                        ? AppTheme.rideAccent
                        : textSecondary,
                  ),
                  tooltip: 'Map Only',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _viewMode = RadarViewMode.fullMap),
                ),
                IconButton(
                  icon: Icon(
                    Icons.list_rounded,
                    size: 18,
                    color: _viewMode == RadarViewMode.listOnly
                        ? AppTheme.rideAccent
                        : textSecondary,
                  ),
                  tooltip: 'List Only',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _viewMode = RadarViewMode.listOnly),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Go Offline Icon Button (compact and clean)
          IconButton(
            icon: const Icon(
              Icons.power_settings_new_rounded,
              size: 20,
              color: Color(0xFFDC2626),
            ),
            tooltip: 'Go Offline',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            onPressed: _leaveRadar,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(
        isDark: isDark,
        cardBg: cardBg,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      ),
    );
  }

  Widget _buildBody({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (_isLoadingLocation) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 14),
            Text(
              'Finding students nearby...',
              style: GoogleFonts.dmSans(fontSize: 13, color: textSecondary),
            ),
          ],
        ),
      );
    }

    if (_permissionDenied || (_errorMessage != null && _currentPosition == null)) {
      return _buildPermissionState(
        isDark: isDark,
        cardBg: cardBg,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      );
    }

    return StreamBuilder<List<CampusHubPresence>>(
      stream: _radarService.watchAllActivePresences(),
      builder: (context, snapshot) {
        final rawPresences = snapshot.data ?? [];
        final presences = rawPresences
            .where((p) => p.isActiveWithin20Mins && !p.isExpired)
            .toList();

        // Sort presences by direct proximity to current user
        if (_currentPosition != null) {
          presences.sort((a, b) {
            final distA = a.distanceInMetersFrom(
                    _currentPosition!.latitude, _currentPosition!.longitude) ??
                double.infinity;
            final distB = b.distanceInMetersFrom(
                    _currentPosition!.latitude, _currentPosition!.longitude) ??
                double.infinity;
            return distA.compareTo(distB);
          });
        }

        switch (_viewMode) {
          case RadarViewMode.split:
            return _buildSplitView(
              presences: presences,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            );
          case RadarViewMode.fullMap:
            return _buildFullMapView(
              presences: presences,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            );
          case RadarViewMode.listOnly:
            return _buildListOnlyView(
              presences: presences,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            );
        }
      },
    );
  }

  // ── Split View (Interactive Map Top + List Bottom) ─────────────────────────

  Widget _buildSplitView({
    required List<CampusHubPresence> presences,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      children: [
        // Map Container
        Expanded(
          flex: 4,
          child: Stack(
            children: [
              _buildMapWidget(
                presences: presences,
                isDark: isDark,
                borderColor: borderColor,
                textPrimary: textPrimary,
              ),

              // Recenter Floating Button
              Positioned(
                right: 14,
                bottom: 14,
                child: FloatingActionButton.small(
                  heroTag: 'radar_screen_recenter',
                  onPressed: _centerMapOnUser,
                  backgroundColor: cardBg,
                  foregroundColor: textPrimary,
                  elevation: 3,
                  child: const Icon(Icons.my_location_rounded, size: 18),
                ),
              ),
            ],
          ),
        ),

        // Status bar showing active count & GPS coordinates
        _buildCurrentStatusBar(
          allCount: presences.length,
          isDark: isDark,
          borderColor: borderColor,
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),

        // Scrollable List of Students
        Expanded(
          flex: 5,
          child: presences.isEmpty
              ? _buildEmptyState(
                  isDark: isDark,
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: presences.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final presence = presences[index];
                    return _buildUserCard(
                      presence: presence,
                      isSelected: _selectedPresence?.id == presence.id,
                      onCardTap: () {
                        setState(() => _selectedPresence = presence);
                        _centerMapOnPresence(presence);
                      },
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Full Map View ──────────────────────────────────────────────────────────

  Widget _buildFullMapView({
    required List<CampusHubPresence> presences,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Stack(
      children: [
        _buildMapWidget(
          presences: presences,
          isDark: isDark,
          borderColor: borderColor,
          textPrimary: textPrimary,
        ),

        // Top Status pill
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cardBg.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Text(
                  '${presences.length} Active Peer${presences.length == 1 ? '' : 's'} on Radar',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap pins to view details',
                  style: GoogleFonts.dmSans(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
        ),

        // Floating selected student card at bottom
        if (_selectedPresence != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 96,
            child: _buildUserCard(
              presence: _selectedPresence!,
              isSelected: true,
              onCardTap: () {},
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),

        // Recenter FAB
        Positioned(
          right: 16,
          bottom: _selectedPresence != null ? 220 : 96,
          child: FloatingActionButton.small(
            heroTag: 'radar_screen_fullmap_recenter',
            onPressed: _centerMapOnUser,
            backgroundColor: cardBg,
            foregroundColor: textPrimary,
            elevation: 3,
            child: const Icon(Icons.my_location_rounded, size: 18),
          ),
        ),
      ],
    );
  }

  // ── List Only View ─────────────────────────────────────────────────────────

  Widget _buildListOnlyView({
    required List<CampusHubPresence> presences,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      children: [
        _buildCurrentStatusBar(
          allCount: presences.length,
          isDark: isDark,
          borderColor: borderColor,
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        Expanded(
          child: presences.isEmpty
              ? _buildEmptyState(
                  isDark: isDark,
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: presences.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final presence = presences[index];
                    return _buildUserCard(
                      presence: presence,
                      isSelected: false,
                      onCardTap: () {},
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Map Widget ─────────────────────────────────────────────────────────────

  Widget _buildMapWidget({
    required List<CampusHubPresence> presences,
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
  }) {
    final centerLat = _currentPosition?.latitude ?? 20.9320;
    final centerLon = _currentPosition?.longitude ?? 85.2555;

    final markers = <Marker>[];

    // Nearby Active Students Pins
    for (final presence in presences) {
      if (presence.latitude == null || presence.longitude == null) continue;
      final isMe = presence.userId == widget.currentUser.id;
      final isSelected = _selectedPresence?.id == presence.id;

      markers.add(
        Marker(
          point: LatLng(presence.latitude!, presence.longitude!),
          width: 48,
          height: 54,
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedPresence = presence);
              _centerMapOnPresence(presence);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF16A34A)
                        : (isSelected ? AppTheme.rideAccent : textPrimary),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    backgroundImage: presence.userAvatar != null &&
                            presence.userAvatar!.isNotEmpty
                        ? CachedNetworkImageProvider(presence.userAvatar!)
                        : null,
                    child: (presence.userAvatar == null || presence.userAvatar!.isEmpty)
                        ? Text(
                            presence.userName.isNotEmpty
                                ? presence.userName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.syne(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          )
                        : null,
                  ),
                ),
                CustomPaint(
                  size: const Size(10, 6),
                  painter: _TrianglePainter(
                    color: isMe
                        ? const Color(0xFF16A34A)
                        : (isSelected ? AppTheme.rideAccent : textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Current User GPS Marker with Pulse ring
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 32,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLon),
        initialZoom: 14.5,
        minZoom: 10.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: isDark
              ? 'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.market.app.market_app',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  // ── Status Bar ─────────────────────────────────────────────────────────────

  Widget _buildCurrentStatusBar({
    required int allCount,
    required bool isDark,
    required Color borderColor,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final titleText = allCount == 0
        ? 'Searching nearby...'
        : '$allCount student${allCount == 1 ? '' : 's'} active nearby';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.my_location_rounded, size: 15, color: AppTheme.rideAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Active within last 20 mins',
                  style: GoogleFonts.dmSans(fontSize: 10, color: textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 6, color: Color(0xFF16A34A)),
                const SizedBox(width: 4),
                Text(
                  'Live',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Student Card ───────────────────────────────────────────────────────────

  Widget _buildUserCard({
    required CampusHubPresence presence,
    required bool isSelected,
    required VoidCallback onCardTap,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isMe = presence.userId == widget.currentUser.id;
    final distanceText = _currentPosition != null
        ? presence.formattedDistanceFrom(
            _currentPosition!.latitude, _currentPosition!.longitude)
        : '';
    final timeText = presence.timeAgo;
    final hasLocationName = presence.locationName != null &&
        presence.locationName!.trim().isNotEmpty &&
        !presence.locationName!.contains('°');

    return InkWell(
      onTap: onCardTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.rideAccent
                : (isMe ? AppTheme.rideAccent.withValues(alpha: 0.4) : borderColor),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with Online dot
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                      backgroundImage: presence.userAvatar != null &&
                              presence.userAvatar!.isNotEmpty
                          ? CachedNetworkImageProvider(presence.userAvatar!)
                          : null,
                      child: (presence.userAvatar == null || presence.userAvatar!.isEmpty)
                          ? Text(
                              presence.userName.isNotEmpty
                                  ? presence.userName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.syne(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBg, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),

                // Name, Role & Verification
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isMe ? '${presence.userName} (You)' : presence.userName,
                              style: GoogleFonts.syne(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          VerificationBadge(
                            size: VerificationBadgeSize.compact,
                            status: presence.verificationStatus,
                            role: presence.userRole,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· $timeText',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Distance Pill
                if (distanceText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.rideAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.near_me_rounded, size: 10, color: AppTheme.rideAccent),
                        const SizedBox(width: 3),
                        Text(
                          distanceText,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.rideAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            if (hasLocationName) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFFEA580C)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Near ${presence.locationName}',
                      style: GoogleFonts.dmSans(fontSize: 11, color: textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            if (presence.note != null && presence.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '"${presence.note!.trim()}"',
                style: GoogleFonts.dmSans(fontSize: 11, fontStyle: FontStyle.italic, color: textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Action Buttons
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => showIdCardDialog(context, presence.userId),
                  icon: const Icon(Icons.badge_outlined, size: 13),
                  label: Text(
                    'Student ID',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Spacer(),
                if (!isMe && presence.phoneNumber.isNotEmpty) ...[
                  IconButton(
                    onPressed: () => _launchWhatsApp(presence.phoneNumber),
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: Color(0xFF25D366)),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    tooltip: 'WhatsApp',
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => _launchCall(presence.phoneNumber),
                    icon: const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF16A34A)),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    tooltip: 'Call',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState({
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.radar_rounded, size: 36, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 14),
            Text(
              'No students active nearby',
              style: GoogleFonts.syne(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You are live on the map. Students active within the last 20 minutes will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 12, height: 1.4, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ── Permission State ───────────────────────────────────────────────────────

  Widget _buildPermissionState({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off_rounded, size: 36, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 16),
            Text(
              'Location Access Needed',
              style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Turn on location to find students near you.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 13, height: 1.4, color: textSecondary),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _checkAndRequestLocation,
              icon: const Icon(Icons.my_location_rounded, size: 16),
              label: Text(
                'Turn on Location',
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.rideAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
