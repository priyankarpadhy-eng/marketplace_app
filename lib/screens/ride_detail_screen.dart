import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/app_user.dart';
import '../models/ride.dart';
import '../services/ride_service.dart';
import '../services/auth_service.dart';
import '../services/deep_link_service.dart';
import '../theme/app_theme.dart';
import '../widgets/id_card_dialog.dart';
import '../widgets/verification_badge.dart';
import 'ride_chat_screen.dart';

class RideDetailScreen extends StatelessWidget {
  final Ride ride;
  final AppUser currentUser;

  const RideDetailScreen({
    super.key,
    required this.ride,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final service = RideService();
    final isOrganizer = ride.organizerId == currentUser.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);

    final isPast = ride.departureTime.isBefore(DateTime.now());
    final isCancelled = ride.status == 'cancelled';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ride Details',
              style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            Text(
              '#${ride.rideNumber} · Split & Share',
              style: GoogleFonts.dmSans(fontSize: 11, color: textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () => DeepLinkService.shareRide(ride),
            tooltip: 'Share Ride',
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RideChatScreen(ride: ride, currentUser: currentUser),
                ),
              );
            },
            tooltip: 'Ride Chat',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.watchParticipants(ride.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final participants = snapshot.data ?? [];
          final isInParticipantList = participants.any((d) => d['user_id'] == currentUser.id);
          final canSeeContacts = isInParticipantList || isOrganizer;
          final seatsRemaining = (ride.totalSeats - participants.length).clamp(0, ride.totalSeats);

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  // 1. Route Visualizer Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Pill + Gender Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCancelled
                                    ? const Color(0xFFFEE2E2)
                                    : (isPast
                                        ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
                                        : const Color(0xFFDCFCE7)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isCancelled ? 'CANCELLED' : (isPast ? 'COMPLETED' : 'ACTIVE RIDE'),
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isCancelled
                                      ? const Color(0xFFB91C1C)
                                      : (isPast
                                          ? (isDark ? Colors.white70 : const Color(0xFF475569))
                                          : const Color(0xFF15803D)),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                ride.genderPreference == 'female'
                                    ? 'Female Only'
                                    : (ride.genderPreference == 'male' ? 'Male Only' : 'Mixed Genders'),
                                style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Route visual flow
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.trip_origin_rounded, size: 18, color: Color(0xFF16A34A)),
                                Container(
                                  width: 2,
                                  height: 38,
                                  color: borderColor,
                                ),
                                const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFFEA580C)),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pickup',
                                    style: GoogleFonts.dmSans(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    ride.from,
                                    style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Drop-off',
                                    style: GoogleFonts.dmSans(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    ride.to,
                                    style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Route Map Preview
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(
                                  (_resolveLocation(ride.from).latitude + _resolveLocation(ride.to).latitude) / 2,
                                  (_resolveLocation(ride.from).longitude + _resolveLocation(ride.to).longitude) / 2,
                                ),
                                initialZoom: 11.2,
                                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: isDark
                                      ? 'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
                                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.market.app.market_app',
                                ),
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: [
                                        _resolveLocation(ride.from),
                                        _resolveLocation(ride.to),
                                      ],
                                      strokeWidth: 3.0,
                                      color: AppTheme.rideAccent,
                                    ),
                                  ],
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _resolveLocation(ride.from),
                                      width: 18,
                                      height: 18,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF16A34A),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.circle, size: 6, color: Colors.white),
                                      ),
                                    ),
                                    Marker(
                                      point: _resolveLocation(ride.to),
                                      width: 20,
                                      height: 20,
                                      child: const Icon(Icons.location_on, size: 20, color: Color(0xFFEA580C)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),

                        // Departure Time Row
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 16, color: AppTheme.rideAccent),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('EEE, MMM d · h:mm a').format(ride.departureTime),
                              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            const Spacer(),
                            Text(
                              isPast ? 'Departed' : _formatRemainingTime(ride.departureTime),
                              style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.rideAccent),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Seat Capacity Progress Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SEAT OCCUPANCY',
                              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.8),
                            ),
                            Text(
                              '${participants.length} of ${ride.totalSeats} Booked',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: seatsRemaining == 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (participants.length / ride.totalSeats).clamp(0.0, 1.0),
                            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              seatsRemaining == 0 ? const Color(0xFFDC2626) : AppTheme.rideAccent,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          seatsRemaining == 0
                              ? 'This ride is fully booked.'
                              : '$seatsRemaining empty seat${seatsRemaining == 1 ? '' : 's'} remaining to split auto fare.',
                          style: GoogleFonts.dmSans(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Organizer Profile Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HOSTED BY',
                          style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppTheme.surfaceAlt(isDark),
                              child: Text(
                                ride.organizerName.isNotEmpty ? ride.organizerName[0].toUpperCase() : '?',
                                style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          isOrganizer ? '${ride.organizerName} (You)' : ride.organizerName,
                                          style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance.collection('users').doc(ride.organizerId).get(),
                                        builder: (context, snap) {
                                          if (!snap.hasData || snap.data?.data() == null) {
                                            return const SizedBox.shrink();
                                          }
                                          final data = snap.data!.data() as Map<String, dynamic>;
                                          return VerificationBadge(
                                            size: VerificationBadgeSize.compact,
                                            status: data['verification_status']?.toString() ?? 'unverified',
                                            role: data['role']?.toString() ?? 'student',
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ride Organizer · Arranges Auto',
                                    style: GoogleFonts.dmSans(fontSize: 12, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => showIdCardDialog(context, ride.organizerId),
                              icon: const Icon(Icons.verified_user_outlined, size: 14),
                              label: Text('Doc', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.rideAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        if (canSeeContacts && ride.organizerPhone.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.phone_outlined, size: 15, color: textSecondary),
                                const SizedBox(width: 8),
                                Text(ride.organizerPhone, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary)),
                                const Spacer(),
                                if (!isOrganizer) ...[
                                  IconButton(
                                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: Color(0xFF25D366)),
                                    onPressed: () => _launchWhatsApp(ride.organizerPhone),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.call, size: 16, color: Color(0xFF16A34A)),
                                    onPressed: () => _launchCall(ride.organizerPhone),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Participants List
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CONFIRMED RIDERS (${participants.length})',
                              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 0.8),
                            ),
                            if (!canSeeContacts)
                              Text(
                                'Contacts unlocked when joined',
                                style: GoogleFonts.dmSans(fontSize: 10, color: textSecondary),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (participants.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No participants yet. Be the first to join!',
                              style: GoogleFonts.dmSans(fontSize: 12, color: textSecondary),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: participants.length,
                            separatorBuilder: (context, i) => const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final p = participants[index];
                              final pUserId = p['user_id'] ?? '';
                              final pName = p['user_name'] ?? 'Peer Student';
                              final pPhone = p['user_phone'] ?? '';
                              final isOrg = p['role'] == 'organizer' || pUserId == ride.organizerId;
                              final isMe = pUserId == currentUser.id;

                              return Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isOrg
                                        ? AppTheme.rideAccent.withValues(alpha: 0.15)
                                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
                                    child: Text(
                                      pName.isNotEmpty ? pName[0].toUpperCase() : '?',
                                      style: GoogleFonts.syne(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isOrg ? AppTheme.rideAccent : textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                isMe ? '$pName (You)' : pName,
                                                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isOrg) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.rideAccent.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Host',
                                                  style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.rideAccent),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (canSeeContacts && pPhone.isNotEmpty)
                                          Text(
                                            pPhone,
                                            style: GoogleFonts.dmSans(fontSize: 11, color: textSecondary),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.badge_outlined, size: 18),
                                    onPressed: () => showIdCardDialog(context, pUserId),
                                    tooltip: 'Inspect Student ID',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  if (canSeeContacts && !isMe && pPhone.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    IconButton(
                                      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: Color(0xFF25D366)),
                                      onPressed: () => _launchWhatsApp(pPhone),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      icon: const Icon(Icons.call, size: 16, color: Color(0xFF16A34A)),
                                      onPressed: () => _launchCall(pPhone),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                  if (isOrganizer && !isOrg) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 18, color: Color(0xFFDC2626)),
                                      onPressed: () => _confirmKick(context, service, ride.id, pUserId, pName),
                                      tooltip: 'Remove participant',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // 5. Sticky Bottom Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border(top: BorderSide(color: borderColor)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: _buildBottomActions(
                      context,
                      service: service,
                      isOrganizer: isOrganizer,
                      isParticipant: isInParticipantList,
                      seatsRemaining: seatsRemaining,
                      isCancelled: isCancelled,
                      isPast: isPast,
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

  Widget _buildBottomActions(
    BuildContext context, {
    required RideService service,
    required bool isOrganizer,
    required bool isParticipant,
    required int seatsRemaining,
    required bool isCancelled,
    required bool isPast,
  }) {
    if (isCancelled) {
      return Center(
        child: Text(
          'This ride was cancelled by the host',
          style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFFDC2626), fontWeight: FontWeight.bold),
        ),
      );
    }

    if (isPast && !isOrganizer && !isParticipant) {
      return Center(
        child: Text(
          'This ride has already departed',
          style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (isOrganizer) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _confirmCancelRide(context, service),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFDC2626)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: Text('Cancel Ride', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RideChatScreen(ride: ride, currentUser: currentUser)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.rideAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              icon: const Icon(Icons.chat_bubble_rounded, size: 16),
              label: Text('Open Group Chat', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    if (isParticipant) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _confirmLeaveRide(context, service),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFDC2626)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.exit_to_app_rounded, size: 16),
              label: Text('Leave', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RideChatScreen(ride: ride, currentUser: currentUser)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.rideAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              icon: const Icon(Icons.chat_bubble_rounded, size: 16),
              label: Text('Open Group Chat', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    // Not a participant yet
    final isFull = seatsRemaining <= 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isFull ? null : () => _showJoinConfirmationSheet(context, service),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.rideAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(
          isFull ? 'Ride Fully Booked' : 'Join Ride · Split Fare ($seatsRemaining left)',
          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showJoinConfirmationSheet(BuildContext context, RideService service) {
    final phoneController = TextEditingController(text: currentUser.phoneNumber);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
          final border = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirm Joining Ride',
                    style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${ride.from} → ${ride.to} · ${DateFormat('h:mm a').format(ride.departureTime)}',
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.rideAccent, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Contact Phone Number:',
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Enter 10-digit number for coordination',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Fair Split: Upon arrival, you will split the auto fare equally with fellow co-riders.',
                      style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF92400E)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final phone = phoneController.text.trim();
                              if (phone.isEmpty || phone.length < 10) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Please enter a valid 10-digit number')),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              try {
                                final updatedUser = currentUser.copyWith(phoneNumber: phone);
                                await AuthService.instance.updateUserProfile(updatedUser);
                                await service.joinRide(ride: ride, user: updatedUser);

                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Joined ride successfully! Open chat to coordinate.'),
                                      backgroundColor: Color(0xFF16A34A),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Failed to join: $e')),
                                  );
                                }
                              } finally {
                                if (ctx.mounted) setModalState(() => isSaving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.rideAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Confirm & Reserve Seat', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmLeaveRide(BuildContext context, RideService service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave Ride?'),
        content: const Text('Your seat will be released for other students to claim.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await service.leaveRide(ride: ride, user: currentUser);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left ride.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
  }

  Future<void> _confirmCancelRide(BuildContext context, RideService service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Ride?'),
        content: const Text('This will cancel the ride for all participants.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Ride', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await service.cancelRide(ride);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
  }

  Future<void> _confirmKick(BuildContext context, RideService service, String rideId, String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove $name?'),
        content: const Text('This will remove the student and free up their seat.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await service.kickParticipant(rideId: rideId, userId: userId, userName: name);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name removed from ride.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
  }

  static void _launchWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final url = 'https://wa.me/91$cleanPhone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  static void _launchCall(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  static LatLng _resolveLocation(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('talcher') && (lower.contains('station') || lower.contains('road'))) {
      return const LatLng(20.9507, 85.2281);
    }
    if (lower.contains('angul') && lower.contains('station')) {
      return const LatLng(20.8443, 85.1011);
    }
    if (lower.contains('bus') || (lower.contains('angul') && lower.contains('stand'))) {
      return const LatLng(20.8385, 85.1054);
    }
    if (lower.contains('banarpal')) {
      return const LatLng(20.8710, 85.1610);
    }
    if (lower.contains('thermal') || lower.contains('hatatota')) {
      return const LatLng(20.9160, 85.2020);
    }
    return const LatLng(20.9320, 85.2555);
  }

  String _formatRemainingTime(DateTime departure) {
    final diff = departure.difference(DateTime.now());
    if (diff.isNegative) return 'Departing now';
    if (diff.inHours > 24) return 'Departs in ${diff.inDays}d';
    if (diff.inHours > 0) return 'Departs in ${diff.inHours}h ${diff.inMinutes % 60}m';
    return 'Departs in ${diff.inMinutes}m';
  }
}
