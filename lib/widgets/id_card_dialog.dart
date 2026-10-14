import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import 'verification_badge.dart';

void showIdCardDialog(BuildContext context, String userId) {
  showDialog(
    context: context,
    builder: (context) => _IdCardDialogContent(userId: userId),
  );
}

class _IdCardDialogContent extends StatefulWidget {
  final String userId;

  const _IdCardDialogContent({required this.userId});

  @override
  State<_IdCardDialogContent> createState() => _IdCardDialogContentState();
}

class _IdCardDialogContentState extends State<_IdCardDialogContent> {
  AppUser? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _user = AppUser.fromMap(doc.id, doc.data()!);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'User not found.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching verification: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface(isDark),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _user == null) {
      return AlertDialog(
        backgroundColor: AppTheme.surface(isDark),
        title: Text('Error', style: TextStyle(color: AppTheme.textPrimary(isDark))),
        content: Text(_error ?? 'Could not load user data.', style: TextStyle(color: AppTheme.textPrimary(isDark))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }

    final hasIdCard = _user!.idCardImage != null && _user!.idCardImage!.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.surfaceAlt(isDark),
                  backgroundImage: _user!.profileImage != null ? CachedNetworkImageProvider(_user!.profileImage!) : null,
                  child: _user!.profileImage == null
                      ? Text(
                          _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                          style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(isDark)),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user!.name,
                        style: GoogleFonts.syne(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      VerificationBadge(
                        user: _user,
                        size: VerificationBadgeSize.standard,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contact info card (Phone & Email)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_user!.phoneNumber.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 15, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text(
                          'Phone: ',
                          style: GoogleFonts.dmSans(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                        ),
                        Text(
                          _user!.phoneNumber,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 15, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        'Email: ',
                        style: GoogleFonts.dmSans(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                      Expanded(
                        child: Text(
                          _user!.email,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Status notice
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _user!.isPendingVerification
                    ? const Color(0xFFFEF3C7)
                    : (_user!.isApprovedVerification
                        ? const Color(0xFFDCFCE7)
                        : (_user!.isRejectedVerification ? const Color(0xFFFEE2E2) : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)))),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _user!.isPendingVerification
                        ? Icons.hourglass_top_rounded
                        : (_user!.isApprovedVerification
                            ? Icons.verified_user_rounded
                            : (_user!.isRejectedVerification ? Icons.cancel_outlined : Icons.shield_outlined)),
                    size: 16,
                    color: _user!.isPendingVerification
                        ? const Color(0xFFB45309)
                        : (_user!.isApprovedVerification
                            ? const Color(0xFF15803D)
                            : (_user!.isRejectedVerification ? const Color(0xFFB91C1C) : const Color(0xFF64748B))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _user!.isPendingVerification
                          ? 'Document submitted & pending review by campus admin.'
                          : (_user!.isApprovedVerification
                              ? 'Affiliation verified by campus administration.'
                              : (_user!.isRejectedVerification
                                  ? 'Submission rejected. Awaiting re-submission.'
                                  : 'No verification document submitted (Unverified).')),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _user!.isPendingVerification
                            ? const Color(0xFF92400E)
                            : (_user!.isApprovedVerification
                                ? const Color(0xFF166534)
                                : (_user!.isRejectedVerification ? const Color(0xFF991B1B) : (isDark ? Colors.white70 : const Color(0xFF475569)))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (hasIdCard) ...[
              Text(
                'Uploaded Verification Document',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: _user!.idCardImage!,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        height: 220,
                        color: AppTheme.surfaceAlt(isDark),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 220,
                        color: AppTheme.surfaceAlt(isDark),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, color: AppTheme.textSecondary(isDark), size: 40),
                            const SizedBox(height: 8),
                            Text('Failed to load document', style: TextStyle(color: AppTheme.textSecondary(isDark))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pinch to zoom in or inspect document details.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ] else
              Container(
                height: 130,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt(isDark),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706), size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'No verification document on file',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This user is currently browsing as unverified.',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
