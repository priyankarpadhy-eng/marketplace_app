import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/ride.dart';
import '../services/ride_service.dart';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/ride_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/deep_link_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:slide_to_act/slide_to_act.dart' as slide_to_act;
import '../theme/app_theme.dart';

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
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('${ride.from} → ${ride.to}', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontSize: 18)),
        iconTheme: IconThemeData(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: AppTheme.rideAccent),
            onPressed: () => DeepLinkService.shareRide(ride),
            tooltip: 'Share Ride',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.watchParticipants(ride.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading participants: ${snapshot.error}'));
          }
          
          final docs = snapshot.data ?? [];
          final isInParticipantList = docs.any((d) => d['user_id'] == currentUser.id);
          final isViewingOwnRide = ride.organizerId == currentUser.id;
          final canSeeContacts = isInParticipantList || isViewingOwnRide;

          return CustomScrollView(
            slivers: [
              // 1. Ride Card
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RideCard(ride: ride, onTap: null),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              
              // 2. Participants Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.rideAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.people_rounded, size: 16, color: AppTheme.rideAccent),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Participants',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: docs.length >= ride.totalSeats ? AppTheme.success.withOpacity(0.1) : AppTheme.rideAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: docs.length >= ride.totalSeats ? AppTheme.success.withOpacity(0.2) : AppTheme.rideAccent.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          '${docs.length}/${ride.totalSeats} seats',
                          style: GoogleFonts.outfit(
                            color: docs.length >= ride.totalSeats ? AppTheme.success : AppTheme.rideAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Privacy Notice
              if (!canSeeContacts)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.rideAccent.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.rideAccent.withOpacity(0.12)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.rideAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.privacy_tip_outlined, color: AppTheme.rideAccent, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Contact details are hidden for privacy. Join this ride to coordinate with others.",
                              style: GoogleFonts.outfit(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. Participant List
              if (docs.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 40, color: isDark ? AppTheme.darkTextSecondary.withOpacity(0.3) : AppTheme.lightTextSecondary.withOpacity(0.3)),
                          const SizedBox(height: 8),
                          Text('No participants yet', style: GoogleFonts.outfit(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = docs[index];
                      final name = (data['user_name'] as String?) ?? 'Student';
                      final role = (data['role'] as String?) ?? 'participant';
                      final isOrg = role == 'organizer';

                      String userPhone = (data['user_phone'] as String?) ?? '';
                      if (isOrg && userPhone.isEmpty) {
                        userPhone = ride.organizerPhone;
                      }
                      final isMe = data['user_id'] == currentUser.id;
                      final isPhoneVerified = (data['user_phone_verified'] as bool?) ?? false;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isOrg ? AppTheme.rideAccent.withOpacity(0.1) : (isDark ? AppTheme.darkSurfaceAlt : AppTheme.lightSurfaceAlt),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(isOrg ? Icons.star_rounded : Icons.person_rounded, color: isOrg ? AppTheme.rideAccent : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary), size: 20),
                            ),
                            title: Row(
                              children: [
                                Flexible(child: Text(name + (isMe ? ' (You)' : ''), style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
                                if (isPhoneVerified)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(Icons.verified, color: AppTheme.rideAccent, size: 16),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isOrg ? 'Organizer' : 'Participant', style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 11)),
                                if (canSeeContacts && userPhone.isNotEmpty)
                                  Text(userPhone, style: TextStyle(color: AppTheme.rideAccent, fontWeight: FontWeight.w600, fontSize: 12)),
                              ],
                            ),
                            trailing: (canSeeContacts && !isMe) ? Row(
                              mainAxisSize: MainAxisSize.min, 
                              children: [
                                if (isOrganizer && !isOrg)
                                  IconButton(
                                    icon: Icon(Icons.person_remove_outlined, color: AppTheme.error, size: 20),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          title: const Text('Kick Participant?'),
                                          content: Text('Are you sure you want to remove $name from the ride?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kick', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      ) ?? false;
                                      if (confirm) {
                                        try {
                                          await service.kickParticipant(
                                            rideId: ride.id,
                                            userId: data['user_id'],
                                            userName: name,
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name removed.')));
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to kick: $e')));
                                        }
                                      }
                                    },
                                  ),
                                if (userPhone.isNotEmpty) ...[
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF25D366).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: IconButton(
                                      icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 18), 
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      padding: EdgeInsets.zero,
                                      onPressed: () async { 
                                        final cleanPhone = userPhone.replaceAll(RegExp(r'\D'), ''); 
                                        final url = "https://wa.me/91$cleanPhone"; 
                                        if (await canLaunchUrl(Uri.parse(url))) { 
                                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); 
                                        } 
                                      }
                                    ), 
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.rideAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.phone_forwarded, color: AppTheme.rideAccent, size: 18), 
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                      padding: EdgeInsets.zero,
                                      onPressed: () async { 
                                        final url = "tel:$userPhone"; 
                                        if (await canLaunchUrl(Uri.parse(url))) { 
                                          await launchUrl(Uri.parse(url)); 
                                        } 
                                      }
                                    ),
                                  ),
                                ] else if (!isOrganizer || isOrg)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text("No number", style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 10)),
                                  )
                              ]
                            ) : null,
                          ),
                        ),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),

              // 5. Action Buttons & Safety Notice
              SliverFillRemaining(
                hasScrollBody: false,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PrimaryActions(
                          ride: ride,
                          currentUser: currentUser,
                          isParticipant: isInParticipantList,
                          isOrganizer: isOrganizer,
                          participants: docs,
                          service: service,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurfaceAlt.withOpacity(0.3) : AppTheme.lightSurfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.auto_delete_outlined, size: 18, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "All ride coordination data is automatically purged 24 hours after departure.",
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}

class _PrimaryActions extends StatefulWidget {
  final Ride ride;
  final AppUser currentUser;
  final bool isParticipant;
  final bool isOrganizer;
  final List<Map<String, dynamic>> participants;
  final RideService service;

  const _PrimaryActions({
    required this.ride,
    required this.currentUser,
    required this.isParticipant,
    required this.isOrganizer,
    required this.participants,
    required this.service,
  });

  @override
  State<_PrimaryActions> createState() => _PrimaryActionsState();
}

class _PrimaryActionsState extends State<_PrimaryActions> {
  bool _busy = false;
  late bool _isEditingPhone;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _isEditingPhone = widget.currentUser.phoneNumber.isEmpty || !widget.currentUser.phoneVerified;
    _phoneController = TextEditingController(text: widget.currentUser.phoneNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  int get seatsTaken => widget.participants.length;

  bool get isFull => seatsTaken >= widget.ride.totalSeats;

  Future<bool> _savePhoneInline() async {
    final text = _phoneController.text.trim();
    if (text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit number')));
      return false;
    }
    setState(() => _busy = true);
    try {
      final updatedUser = widget.currentUser.copyWith(
        phoneNumber: text,
        phoneVerified: (text == widget.currentUser.phoneNumber && widget.currentUser.phoneVerified),
      );
      await AuthService.instance.updateUserProfile(updatedUser);
      setState(() {
        _isEditingPhone = false;
      });
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save phone: $e')));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleJoin() async {
    // Guard: ride is in the past
    final isPast = widget.ride.departureTime.isBefore(DateTime.now());
    if (_busy || isFull || widget.ride.status != 'active' || isPast) return;
    
    // Every time: Verify phone number
    if (_isEditingPhone) {
      final success = await _savePhoneInline();
      if (!success) return;
    }

    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit number before joining.')));
      return;
    }

    setState(() => _busy = true);
    try {
      final updatedUser = widget.currentUser.copyWith(
        phoneNumber: phone,
        phoneVerified: (phone == widget.currentUser.phoneNumber && widget.currentUser.phoneVerified),
      );
      await widget.service.joinRide(
        ride: widget.ride,
        user: updatedUser,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined ride')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _handleLeave() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.service.leaveRide(
        ride: widget.ride,
        user: widget.currentUser,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Left ride')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to leave: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _handleCancel() async {
    if (_busy) return;
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Cancel ride?'),
            content: const Text(
              'This will cancel the ride for everyone.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(true),
                child: const Text('Yes, cancel'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;

    setState(() => _busy = true);
    try {
      await widget.service.cancelRide(widget.ride);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rideActive = widget.ride.status == 'active';
    final isPast     = widget.ride.departureTime.isBefore(DateTime.now());

    // ── Past ride — block all join actions ─────────────────────────
    if (isPast && !widget.isOrganizer) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block_rounded, size: 18, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            const SizedBox(width: 8),
            Text(
              'This ride has already departed',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (!rideActive) {
      return FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          widget.ride.status == 'cancelled'
              ? 'Ride cancelled'
              : 'Ride completed',
        ),
      );
    }

    if (widget.isOrganizer) {
      return FilledButton(
        onPressed: _busy ? null : _handleCancel,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _busy
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Cancel ride', style: TextStyle(fontWeight: FontWeight.w600)),
      );
    }

    if (widget.isParticipant) {
      return FilledButton(
        onPressed: _busy ? null : _handleLeave,
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppTheme.darkSurfaceAlt : AppTheme.lightSurfaceAlt,
          foregroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: _busy
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              )
            : const Text('Leave ride', style: TextStyle(fontWeight: FontWeight.w600)),
      );
    }

    final rideFull = isFull;
    final isShop = widget.currentUser.isShop;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.isParticipant && !isShop && rideActive && !rideFull)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.rideAccent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.rideAccent.withOpacity(0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.rideAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: AppTheme.rideAccent, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Your phone number will be visible to fellow riders for coordination. Always coordinate before the ride starts.",
                    style: GoogleFonts.outfit(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        if (_busy)
          const Center(child: CircularProgressIndicator())
        else if (rideFull || isShop)
          FilledButton(
            onPressed: null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              isShop ? 'Restricted for Shop' : 'Ride full',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.phone_rounded, size: 15, color: AppTheme.rideAccent),
                  const SizedBox(width: 6),
                  Text(
                    'CONTACT NUMBER',
                    style: GoogleFonts.outfit(
                      color: AppTheme.rideAccent, 
                      fontSize: 10, 
                      fontWeight: FontWeight.w800, 
                      letterSpacing: 1.2
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  readOnly: !_isEditingPhone,
                  style: GoogleFonts.outfit(
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, 
                    fontWeight: FontWeight.w600, 
                    fontSize: 14
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? AppTheme.darkSurfaceAlt.withOpacity(0.5) : AppTheme.lightSurfaceAlt.withOpacity(0.8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.rideAccent.withOpacity(0.3), width: 1.5)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.rideAccent, width: 2)),
                    prefixIcon: Icon(Icons.phone_rounded, color: AppTheme.rideAccent, size: 20),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: TextButton(
                        onPressed: () {
                          if (_isEditingPhone) {
                            _savePhoneInline();
                          } else {
                            setState(() {
                              _isEditingPhone = true;
                            });
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: _isEditingPhone ? AppTheme.rideAccent : Colors.transparent,
                        ),
                        child: Text(
                          _isEditingPhone ? 'Save' : 'Edit',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: _isEditingPhone ? Colors.white : AppTheme.rideAccent),
                        ),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                height: 60,
                child: slide_to_act.SlideAction(
                  text: 'SLIDE TO JOIN RIDE',
                  textStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isDark ? AppTheme.darkTextSecondary.withOpacity(0.6) : AppTheme.lightTextSecondary.withOpacity(0.6),
                    letterSpacing: 1.5,
                  ),
                  innerColor: AppTheme.rideAccent,
                  outerColor: AppTheme.rideAccent.withOpacity(0.1),
                  sliderButtonIcon: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                  elevation: 0,
                  borderRadius: 16,
                  sliderButtonIconPadding: 12,
                  sliderRotate: false,
                  submittedIcon: Icon(Icons.check_rounded, color: Colors.white, size: 24),
                  onSubmit: () async {
                    if (_busy) return null;
                    await _handleJoin();
                    return null;
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}
