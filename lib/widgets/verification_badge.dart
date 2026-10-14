import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_user.dart';

enum VerificationBadgeSize { compact, standard, large }

class VerificationBadge extends StatelessWidget {
  final AppUser? user;
  final bool? isVerified;
  final String? status;
  final String? role;
  final VerificationBadgeSize size;
  final VoidCallback? onTap;

  const VerificationBadge({
    super.key,
    this.user,
    this.isVerified,
    this.status,
    this.role,
    this.size = VerificationBadgeSize.compact,
    this.onTap,
  });

  String get _status {
    if (status != null && status!.trim().isNotEmpty) {
      return status!.trim().toLowerCase();
    }
    if (user != null && user!.verificationStatus.trim().isNotEmpty) {
      return user!.verificationStatus.trim().toLowerCase();
    }
    if (isVerified == true) return 'approved';
    return 'none';
  }

  bool get _isApproved => _status == 'approved' || (isVerified ?? user?.isApprovedVerification ?? false);
  bool get _isPending => _status == 'pending' || (user?.isPendingVerification ?? false);
  bool get _isRejected => _status == 'rejected' || (user?.isRejectedVerification ?? false);
  String get _role => (role ?? user?.role ?? 'student').toLowerCase();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isAlumni = _role == 'alumni';

    Color bgColor;
    Color borderColor;
    Color textColor;
    Color iconColor;
    IconData icon;
    String label;

    if (_isApproved) {
      if (isAlumni) {
        bgColor = isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF);
        borderColor = const Color(0xFF6366F1).withValues(alpha: isDark ? 0.4 : 0.3);
        textColor = isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA);
        iconColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);
        icon = Icons.school_rounded;
        label = size == VerificationBadgeSize.compact ? 'Verified' : 'Verified Alumni';
      } else {
        bgColor = isDark ? const Color(0xFF062E24) : const Color(0xFFECFDF5);
        borderColor = const Color(0xFF10B981).withValues(alpha: isDark ? 0.4 : 0.3);
        textColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
        iconColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
        icon = Icons.verified_rounded;
        label = size == VerificationBadgeSize.compact ? 'Verified' : 'Verified Student';
      }
    } else if (_isPending) {
      bgColor = isDark ? const Color(0xFF0C243C) : const Color(0xFFF0F9FF);
      borderColor = const Color(0xFF0284C7).withValues(alpha: isDark ? 0.4 : 0.3);
      textColor = isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1);
      iconColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
      icon = Icons.schedule_rounded;
      label = size == VerificationBadgeSize.compact ? 'Pending' : 'Pending Verification';
    } else if (_isRejected) {
      bgColor = isDark ? const Color(0xFF381418) : const Color(0xFFFFF1F2);
      borderColor = const Color(0xFFE11D48).withValues(alpha: isDark ? 0.4 : 0.3);
      textColor = isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C);
      iconColor = isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
      icon = Icons.error_outline_rounded;
      label = size == VerificationBadgeSize.compact ? 'Rejected' : 'Verification Rejected';
    } else {
      bgColor = isDark ? const Color(0xFF271C0C) : const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.35 : 0.3);
      textColor = isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309);
      iconColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      icon = Icons.shield_outlined;
      label = 'Unverified';
    }

    final double iconSize = switch (size) {
      VerificationBadgeSize.compact => 12.0,
      VerificationBadgeSize.standard => 14.0,
      VerificationBadgeSize.large => 16.0,
    };

    final double fontSize = switch (size) {
      VerificationBadgeSize.compact => 11.0,
      VerificationBadgeSize.standard => 12.0,
      VerificationBadgeSize.large => 14.0,
    };

    final EdgeInsets padding = switch (size) {
      VerificationBadgeSize.compact => const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      VerificationBadgeSize.standard => const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      VerificationBadgeSize.large => const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    };

    final badge = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: textColor,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: badge,
      );
    }

    return badge;
  }
}
