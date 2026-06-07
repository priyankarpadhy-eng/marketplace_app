import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/ride.dart';
import '../services/ride_service.dart';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/ride_card.dart';
import 'ride_chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/deep_link_service.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/guest_login_sheet.dart';
import 'package:slide_to_act/slide_to_act.dart' as slide_to_act;

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
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${ride.from} → ${ride.to}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontSize: 18)),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => DeepLinkService.shareRide(ride),
            tooltip: 'Share Ride',
          ),
          const SizedBox(width: 8),
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
                    RideCard(ride: ride, onTap: null),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              
              // 2. Participants Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Participants',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        '${docs.length}/${ride.totalSeats} seats',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.grey.shade700,
                          fontSize: 13,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.privacy_tip_outlined, color: Colors.blue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Contact details are hidden for privacy. Join this ride to coordinate with others.",
                              style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.blue.shade200 : Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. Participant List
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isOrg ? Theme.of(context).colorScheme.primary : (isDark ? Colors.white12 : Colors.grey.shade100),
                            child: Icon(isOrg ? Icons.star : Icons.person, color: isOrg ? Colors.white : (isDark ? Colors.white70 : Colors.black54), size: 18),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(name + (isMe ? ' (You)' : ''), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 14))),
                              if (isPhoneVerified)
                                const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified, color: Colors.blue, size: 16)),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isOrg ? 'Organizer' : 'Participant', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 11)),
                              if (canSeeContacts)
                                Text(userPhone.isNotEmpty ? userPhone : 'Phone not listed', style: TextStyle(color: userPhone.isNotEmpty ? (isOrg ? Theme.of(context).colorScheme.primary : (isDark ? Colors.blue.shade300 : Colors.blue.shade700)) : Colors.grey, fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                          trailing: (canSeeContacts && !isMe) ? Row(
                            mainAxisSize: MainAxisSize.min, 
                            children: [
                              if (isOrganizer && !isOrg)
                                IconButton(
                                  icon: const Icon(Icons.person_remove_outlined, color: Colors.red, size: 20),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
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
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 20), 
                                  onPressed: () async { 
                                    final cleanPhone = userPhone.replaceAll(RegExp(r'\D'), ''); 
                                    final url = "https://wa.me/91$cleanPhone"; 
                                    if (await canLaunchUrl(Uri.parse(url))) { 
                                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); 
                                    } 
                                  }
                                ), 
                                IconButton(
                                  icon: const Icon(Icons.phone_forwarded, color: Colors.blue, size: 20), 
                                  onPressed: () async { 
                                    final url = "tel:$userPhone"; 
                                    if (await canLaunchUrl(Uri.parse(url))) { 
                                      await launchUrl(Uri.parse(url)); 
                                    } 
                                  }
                                )
                              ] else if (!isOrganizer || isOrg)
                                const Text("No number", style: TextStyle(color: Colors.grey, fontSize: 10))
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
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: isInParticipantList
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RideChatScreen(
                                        ride: ride,
                                        currentUser:
                                            currentUser,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.chat_bubble),
                          label: const Text('Open ride chat'),
                        ),
                        const SizedBox(height: 24),
                        Icon(Icons.auto_delete_outlined, size: 20, color: isDark ? Colors.white24 : Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          "Safety & Privacy: All ride coordination data and chat history are automatically purged 24 hours after departure to protect your privacy.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: isDark ? Colors.white24 : Colors.grey.shade400,
                            height: 1.4,
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

  int get seatsTaken => widget.participants.length;

  bool get isFull => seatsTaken >= widget.ride.totalSeats;

  Future<Map<String, dynamic>?> _showPhoneRequestDialog() async {
    final phoneController = TextEditingController(text: widget.currentUser.phoneNumber);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Confirm Contact Number", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Please confirm your phone number so fellow riders can contact you for the ride. You can update it here if needed."),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Phone Number",
                hintText: "Enter your 10-digit number",
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (phoneController.text.trim().length == 10) {
                Navigator.pop(context, phoneController.text.trim());
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit number')));
              }
            },
            child: const Text("Save & Join", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null) {
      final updatedUser = widget.currentUser.copyWith(
        phoneNumber: result,
        phoneVerified: (result == widget.currentUser.phoneNumber && widget.currentUser.phoneVerified),
      );
      await AuthService.instance.updateUserProfile(updatedUser);
      return {
        'phoneNumber': result,
        'phoneVerified': updatedUser.phoneVerified,
      };
    }
    return null;
  }

  Future<void> _handleJoin() async {
    if (widget.currentUser.isGuest) {
      GuestLoginSheet.show(context);
      return;
    }
    // Guard: ride is in the past
    final isPast = widget.ride.departureTime.isBefore(DateTime.now());
    if (_busy || isFull || widget.ride.status != 'active' || isPast) return;
    
    // Every time: Verify phone number
    final phoneData = await _showPhoneRequestDialog();
    if (phoneData == null) return;

    setState(() => _busy = true);
    try {
      final updatedUser = widget.currentUser.copyWith(
        phoneNumber: phoneData['phoneNumber'],
        phoneVerified: phoneData['phoneVerified'],
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

  Widget _buildSafetyNote() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blueAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Note: Your phone number will be visible to fellow riders for coordination. Always coordinate before the ride starts.",
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueAccent.shade700),
            ),
          ),
        ],
      ),
    );
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
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block_rounded,
              size: 18,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Text(
              'This ride has already departed',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    if (!rideActive) {
      return FilledButton(
        onPressed: null,
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
          backgroundColor: Colors.redAccent,
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
            : const Text(
                'Cancel ride',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
      );
    }

    if (widget.isParticipant) {
      return FilledButton(
        onPressed: _busy ? null : _handleLeave,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.grey.shade800,
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
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
            : const Text(
                'Leave ride',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
      );
    }

    final rideFull = isFull;
    final isShop = widget.currentUser.isShop;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.isParticipant && !isShop && rideActive && !rideFull) _buildSafetyNote(),
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
          SizedBox(
            height: 50,
            child: slide_to_act.SlideAction(
              text: 'Slide to Join Ride',
              textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : Colors.white),
              innerColor: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
              outerColor: isDark ? Colors.white.withOpacity(0.1) : Colors.blue.shade100,
              sliderButtonIcon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
              elevation: 0,
              borderRadius: 16,
              sliderButtonIconPadding: 8,
              onSubmit: () async {
                await _handleJoin();
                return null;
              },
            ),
          ),
      ],
    );
  }
}

