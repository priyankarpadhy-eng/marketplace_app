import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/app_user.dart';
import '../models/campus_hub_presence.dart';
import '../services/campus_radar_service.dart';
import '../theme/app_theme.dart';
import 'id_card_dialog.dart';
import 'verification_badge.dart';

import '../screens/campus_radar_screen.dart';

void showCampusRadarSheet(
  BuildContext context, {
  required AppUser currentUser,
  String? initialHubId,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CampusRadarScreen(currentUser: currentUser),
    ),
  );
}

enum RadarViewMode { split, fullMap, listOnly }

class CampusRadarSheet extends StatefulWidget {
  final AppUser currentUser;
  final String? initialHubId;

  const CampusRadarSheet({
    super.key,
    required this.currentUser,
    this.initialHubId,
  });

  @override
  State<CampusRadarSheet> createState() => _CampusRadarSheetState();
}

class _CampusRadarSheetState extends State<CampusRadarSheet> {
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
          _errorMessage = 'Location services are disabled on your device. Please enable GPS.';
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
            _errorMessage = 'Location permission is required to spot active students near you.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _permissionDenied = true;
          _errorMessage = 'Location permission is permanently denied. Please enable it in App Settings.';
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
          content: Text('You have left the live radar and are no longer visible.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    final uri = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent("Hi, I saw you nearby on the IGIT Live Radar.")}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 12, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFACC15).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.radar_rounded, color: Color(0xFFD97706), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Nearby Students Radar',
                              style: GoogleFonts.syne(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF16A34A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Live',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Active peers around your current place',
                        style: GoogleFonts.dmSans(fontSize: 11, color: textSecondary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // View Mode Toggle Segment
                _buildViewModeToggle(isDark: isDark, textPrimary: textPrimary, textSecondary: textSecondary),

                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Main Body
          Expanded(
            child: _buildBody(
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(
            icon: Icons.splitscreen_rounded,
            tooltip: 'Split View',
            isSelected: _viewMode == RadarViewMode.split,
            onTap: () => setState(() => _viewMode = RadarViewMode.split),
            isDark: isDark,
            textPrimary: textPrimary,
          ),
          _buildToggleOption(
            icon: Icons.map_outlined,
            tooltip: 'Full Map',
            isSelected: _viewMode == RadarViewMode.fullMap,
            onTap: () => setState(() => _viewMode = RadarViewMode.fullMap),
            isDark: isDark,
            textPrimary: textPrimary,
          ),
          _buildToggleOption(
            icon: Icons.view_agenda_outlined,
            tooltip: 'List Only',
            isSelected: _viewMode == RadarViewMode.listOnly,
            onTap: () => setState(() => _viewMode = RadarViewMode.listOnly),
            isDark: isDark,
            textPrimary: textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 15,
            color: isSelected ? textPrimary : (isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
        ),
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
    // 1. Permission request state
    if (_permissionDenied || (_currentPosition == null && _errorMessage != null)) {
      return _buildPermissionRequestView(
        isDark: isDark,
        cardBg: cardBg,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
      );
    }

    // 2. Loading location
    if (_isLoadingLocation && _currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 2.5),
            const SizedBox(height: 16),
            Text(
              'Acquiring GPS location...',
              style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Scanning for active peers near your place',
              style: GoogleFonts.dmSans(fontSize: 12, color: textSecondary),
            ),
          ],
        ),
      );
    }

    // 3. Live active users stream
    return StreamBuilder<List<CampusHubPresence>>(
      stream: _radarService.watchAllActivePresences(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final presences = List<CampusHubPresence>.from(snapshot.data ?? []);

        // Sort by proximity: closest users first
        if (_currentPosition != null) {
          presences.sort((a, b) {
            final distA = a.distanceInMetersFrom(_currentPosition!.latitude, _currentPosition!.longitude) ?? double.infinity;
            final distB = b.distanceInMetersFrom(_currentPosition!.latitude, _currentPosition!.longitude) ?? double.infinity;
            return distA.compareTo(distB);
          });
        }

        if (_viewMode == RadarViewMode.fullMap) {
          return _buildFullMapView(
            presences: presences,
            isDark: isDark,
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          );
        }

        if (_viewMode == RadarViewMode.listOnly) {
          return _buildListOnlyView(
            presences: presences,
            isDark: isDark,
            cardBg: cardBg,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          );
        }

        // Split view (Map top, list bottom)
        return _buildSplitView(
          presences: presences,
          isDark: isDark,
          cardBg: cardBg,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      },
    );
  }

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
        // Interactive Map View
        SizedBox(
          height: 250,
          child: Stack(
            children: [
              _buildMapWidget(
                presences: presences,
                isDark: isDark,
                borderColor: borderColor,
                textPrimary: textPrimary,
              ),

              // Re-center floating button
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: 'radar_recenter_btn',
                  onPressed: _centerMapOnUser,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  foregroundColor: textPrimary,
                  elevation: 2,
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

        const SizedBox(height: 2),

        // Scrollable list of students
        Expanded(
          child: presences.isEmpty
              ? _buildEmptyState(
                  isDark: isDark,
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

        // Floating user count pill
        Positioned(
          top: 12,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${presences.length} Active Nearby',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Re-center floating button
        Positioned(
          right: 14,
          bottom: _selectedPresence != null ? 180 : 20,
          child: FloatingActionButton.small(
            heroTag: 'radar_fullmap_recenter_btn',
            onPressed: _centerMapOnUser,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            foregroundColor: textPrimary,
            elevation: 3,
            child: const Icon(Icons.my_location_rounded, size: 18),
          ),
        ),

        // Selected presence card popup
        if (_selectedPresence != null)
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: _buildUserCard(
              presence: _selectedPresence!,
              isSelected: true,
              onCardTap: () {},
              isDark: isDark,
              cardBg: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderColor: AppTheme.rideAccent,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
      ],
    );
  }

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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildMapWidget({
    required List<CampusHubPresence> presences,
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
  }) {
    final centerLat = _currentPosition?.latitude ?? 20.9320;
    final centerLon = _currentPosition?.longitude ?? 85.2555;

    final markers = <Marker>[];

    // 1. Active students pins (actual location of users)
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
                    backgroundImage: presence.userAvatar != null && presence.userAvatar!.isNotEmpty
                        ? CachedNetworkImageProvider(presence.userAvatar!)
                        : null,
                    child: (presence.userAvatar == null || presence.userAvatar!.isEmpty)
                        ? Text(
                            presence.userName.isNotEmpty ? presence.userName[0].toUpperCase() : '?',
                            style: GoogleFonts.syne(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          )
                        : null,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 14,
                  color: isMe
                      ? const Color(0xFF16A34A)
                      : (isSelected ? AppTheme.rideAccent : textPrimary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. User's exact GPS marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 3,
                ),
              ],
            ),
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

  Widget _buildCurrentStatusBar({
    required int allCount,
    required bool isDark,
    required Color borderColor,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    String coordsLabel = '';
    if (_currentPosition != null) {
      coordsLabel = '${_currentPosition!.latitude.toStringAsFixed(4)}°, ${_currentPosition!.longitude.toStringAsFixed(4)}°';
    }

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
                  '$allCount Active Peer${allCount == 1 ? '' : 's'} in Area',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (coordsLabel.isNotEmpty)
                  Text(
                    'Your GPS: $coordsLabel',
                    style: GoogleFonts.dmSans(fontSize: 10, color: textSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _leaveRadar,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Go Offline',
              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

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
        ? presence.formattedDistanceFrom(_currentPosition!.latitude, _currentPosition!.longitude)
        : '';
    final coordsText = presence.formattedCoords;
    final timeFormatted = DateFormat('h:mm a').format(presence.checkedInAt);

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
                      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                      backgroundImage: presence.userAvatar != null && presence.userAvatar!.isNotEmpty
                          ? CachedNetworkImageProvider(presence.userAvatar!)
                          : null,
                      child: (presence.userAvatar == null || presence.userAvatar!.isEmpty)
                          ? Text(
                              presence.userName.isNotEmpty ? presence.userName[0].toUpperCase() : '?',
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
                            '· $timeFormatted',
                            style: GoogleFonts.dmSans(fontSize: 10, color: textSecondary),
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

            if (coordsText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: const Color(0xFFEA580C)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Location: $coordsText',
                        style: GoogleFonts.dmSans(fontSize: 10, color: textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons row (View ID Doc, Call, WhatsApp)
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => showIdCardDialog(context, presence.userId),
                  icon: const Icon(Icons.verified_user_outlined, size: 12),
                  label: Text(
                    'View ID Doc',
                    style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Spacer(),
                if (!isMe && presence.phoneNumber.isNotEmpty) ...[
                  IconButton(
                    onPressed: () => _launchWhatsApp(presence.phoneNumber),
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 15, color: Color(0xFF25D366)),
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(),
                    tooltip: 'Chat on WhatsApp',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _launchCall(presence.phoneNumber),
                    icon: const Icon(Icons.call_outlined, size: 16, color: Color(0xFF16A34A)),
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints(),
                    tooltip: 'Call Phone',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.radar_outlined, size: 40, color: textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            Text(
              'No Other Students Nearby Right Now',
              style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'You are live on the radar. When other students check the radar around this area, they will appear on your map.',
              style: GoogleFonts.dmSans(fontSize: 12, color: textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequestView({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFACC15).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_searching_rounded, size: 40, color: Color(0xFFD97706)),
          ),
          const SizedBox(height: 20),
          Text(
            'Share Location to Spot Students',
            style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Campus Radar uses your GPS location to instantly show verified students active in your area on the live map.',
            style: GoogleFonts.dmSans(fontSize: 13, color: textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _checkAndRequestLocation,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: Text(
                'Allow Location & Scan',
                style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: textPrimary,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => openAppSettings(),
            child: Text(
              'Open Device Settings',
              style: GoogleFonts.dmSans(fontSize: 13, color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
