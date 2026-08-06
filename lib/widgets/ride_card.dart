import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/deep_link_service.dart';
import '../models/ride.dart';
import 'seat_visualization.dart';
import '../theme/app_theme.dart';
import 'dart:async';

class RideCard extends StatefulWidget {
  final Ride ride;
  final VoidCallback? onTap;

  const RideCard({super.key, required this.ride, this.onTap});

  @override
  State<RideCard> createState() => _RideCardState();
}

class _RideCardState extends State<RideCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isBikeRented = false;
  String _bikeModel = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _fetchRentedBike();
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
      else timer.cancel();
    });
  }

  Future<void> _fetchRentedBike() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('rental_requests')
          .where('renterId', isEqualTo: widget.ride.organizerId)
          .where('status', isEqualTo: 'approved')
          .get();
      if (snapshot.docs.isNotEmpty && mounted) {
        setState(() {
          _isBikeRented = true;
          _bikeModel = snapshot.docs.first.data()['bikeTitle'] ?? 'Bike';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getTimeStatus() {
    if (widget.ride.status == 'cancelled') return 'CANCELLED';
    final now = DateTime.now();
    final diff = widget.ride.departureTime.difference(now);
    if (diff.isNegative) {
      final closingIn = widget.ride.departureTime.add(const Duration(minutes: 30)).difference(now);
      if (closingIn.isNegative || widget.ride.status != 'active') return 'COMPLETED';
      return 'CLOSING IN ${closingIn.inMinutes}M';
    }
    if (widget.ride.status != 'active') return 'COMPLETED';
    if (diff.inHours > 0) return 'STARTS IN ${diff.inHours}H ${diff.inMinutes % 60}M';
    return 'STARTS IN ${diff.inMinutes}M';
  }

  bool _isStartingSoon() {
    if (widget.ride.status != 'active') return false;
    final diff = widget.ride.departureTime.difference(DateTime.now());
    return !diff.isNegative && diff.inMinutes <= 60;
  }

  Color _genderColor(String pref) {
    switch (pref) {
      case 'male': return const Color(0xFF3B82F6);
      case 'female': return const Color(0xFFEC4899);
      default: return AppTheme.rideAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFull = widget.ride.seatsTaken >= widget.ride.totalSeats;
    final seatsLeft = (widget.ride.totalSeats - widget.ride.seatsTaken).clamp(0, 99);
    final status = _getTimeStatus();
    final startingSoon = _isStartingSoon();
    final themeColor = _genderColor(widget.ride.genderPreference);
    final isCompleted = status == 'COMPLETED' || status == 'CANCELLED' || isFull;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface(isDark),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCompleted
                ? AppTheme.border(isDark)
                : themeColor.withOpacity(0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? Colors.black.withOpacity(0.04)
                  : themeColor.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: status badges + share ────────────────
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Active/timing badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.surfaceAlt(isDark)
                                : themeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (startingSoon && !isCompleted)
                                FadeTransition(
                                  opacity: _pulseController,
                                  child: Container(
                                    width: 6, height: 6,
                                    margin: const EdgeInsets.only(right: 5),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  ),
                                ),
                              Text(
                                isFull ? 'BOOKED' : status,
                                style: GoogleFonts.outfit(
                                  color: isCompleted
                                      ? AppTheme.textSecondary(isDark)
                                      : themeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Ride number
                        if (widget.ride.rideNumber != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceAlt(isDark),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#${widget.ride.rideNumber}',
                              style: GoogleFonts.outfit(
                                color: AppTheme.textSecondary(isDark),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        // Gender badge
                        _buildGenderBadge(themeColor, isDark),
                        // Bike badge
                        if (_isBikeRented)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.rideAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.rideAccent.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.motorcycle, color: AppTheme.rideAccent, size: 11),
                                const SizedBox(width: 4),
                                Text(
                                  _bikeModel.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.rideAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Share button
                  GestureDetector(
                    onTap: () => DeepLinkService.shareRide(widget.ride),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt(isDark),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.share_rounded,
                        size: 17,
                        color: AppTheme.textSecondary(isDark),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Route: From → To (gender-gradient container) ──
              _buildRouteContainer(isDark, isCompleted, themeColor),

              const SizedBox(height: 12),

              // ── Footer: organizer + seats ─────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: FaIcon(FontAwesomeIcons.solidUser, size: 9, color: themeColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.ride.organizerName,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(isDark),
                      ),
                    ),
                  ),
                  SeatVisualization(
                    totalSeats: widget.ride.totalSeats,
                    seatsTaken: widget.ride.seatsTaken,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFull
                          ? AppTheme.surfaceAlt(isDark)
                          : AppTheme.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isFull ? 'FULL' : '$seatsLeft LEFT',
                      style: GoogleFonts.outfit(
                        color: isFull
                            ? AppTheme.textSecondary(isDark)
                            : AppTheme.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteContainer(bool isDark, bool isCompleted, Color themeColor) {
    // Gender-based gradient colours
    final List<Color> gradientColors;
    final Color dotColor;
    final Color textOnBg;

    switch (widget.ride.genderPreference) {
      case 'male':
        gradientColors = [const Color(0xFF3B82F6).withOpacity(0.18), const Color(0xFF1D4ED8).withOpacity(0.06)];
        dotColor = const Color(0xFF3B82F6);
        textOnBg = isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E40AF);
        break;
      case 'female':
        gradientColors = [const Color(0xFFEC4899).withOpacity(0.18), const Color(0xFFBE185D).withOpacity(0.06)];
        dotColor = const Color(0xFFEC4899);
        textOnBg = isDark ? const Color(0xFFFCE7F3) : const Color(0xFF9D174D);
        break;
      default: // mixed
        gradientColors = [const Color(0xFFA78BFA).withOpacity(0.18), const Color(0xFF7C3AED).withOpacity(0.06)];
        dotColor = const Color(0xFFA78BFA);
        textOnBg = isDark ? const Color(0xFFEDE9FE) : const Color(0xFF5B21B6);
    }

    final effectiveDot = isCompleted ? AppTheme.border(isDark) : dotColor;
    final effectiveTimeColor = isCompleted ? AppTheme.textSecondary(isDark) : themeColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [AppTheme.surfaceAlt(isDark), AppTheme.surfaceAlt(isDark)]
              : gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? AppTheme.border(isDark) : dotColor.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          // From / To text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: effectiveDot.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'FROM',
                        style: GoogleFonts.outfit(
                          fontSize: 9, fontWeight: FontWeight.w800,
                          color: effectiveDot,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.ride.from,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: effectiveDot.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'TO',
                        style: GoogleFonts.outfit(
                          fontSize: 9, fontWeight: FontWeight.w800,
                          color: effectiveDot,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.ride.to,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.w900,
                          color: isCompleted ? AppTheme.textPrimary(isDark) : textOnBg,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Time column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('hh:mm a').format(widget.ride.departureTime),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900, fontSize: 15,
                  color: effectiveTimeColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('d MMM').format(widget.ride.departureTime),
                style: GoogleFonts.outfit(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary(isDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderBadge(Color color, bool isDark) {
    final isMixed = widget.ride.genderPreference == 'mixed';
    final isMale = widget.ride.genderPreference == 'male';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMixed) ...[
            Icon(Icons.male, color: color, size: 12),
            Icon(Icons.female, color: color, size: 12),
          ] else
            Icon(isMale ? Icons.male : Icons.female, color: color, size: 12),
          const SizedBox(width: 3),
          Text(
            isMixed ? 'ANY' : (isMale ? 'MALE' : 'FEMALE'),
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
