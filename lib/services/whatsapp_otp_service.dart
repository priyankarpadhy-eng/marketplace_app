import 'dart:math';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhatsAppOtpResult {
  final bool isSuccess;
  final String? message;
  final int? cooldownSeconds;
  final bool isLockedOut;

  WhatsAppOtpResult({
    required this.isSuccess,
    this.message,
    this.cooldownSeconds,
    this.isLockedOut = false,
  });
}

class WhatsAppRateLimitStatus {
  final bool isAllowed;
  final int cooldownSeconds;
  final int lockoutRemainingMinutes;
  final int attemptsRemaining;
  final String? message;

  WhatsAppRateLimitStatus({
    required this.isAllowed,
    required this.cooldownSeconds,
    required this.lockoutRemainingMinutes,
    required this.attemptsRemaining,
    this.message,
  });
}

class WhatsAppOtpService {
  WhatsAppOtpService._();
  static final WhatsAppOtpService instance = WhatsAppOtpService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  String get _apiKey =>
      dotenv.env['RENFLAIR_WHATSAPP_API_KEY'] ??
      '0d2612526ed1d3631d06c9447426acc4';

  static const String _country = '91';

  String? _activeOtp;
  String? _activePhone;
  DateTime? _otpGeneratedAt;
  int _failedVerifyAttempts = 0;

  // Rate Limiting Constants
  static const int maxHourlyRequests = 3;
  static const int maxDailyRequests = 5;
  static const int maxFailedVerifyAttempts = 4;
  static const Duration otpValidityDuration = Duration(minutes: 5);
  static const Duration lockoutDuration = Duration(minutes: 30);

  String? get activePhone => _activePhone;

  // ── Rate Limiting Storage & Validation ──────────────────────────────────────

  String _prefKey(String prefix, String phone) => 'renflair_otp_${prefix}_$phone';

  Future<WhatsAppRateLimitStatus> checkRateLimit(String rawPhone) async {
    final phone = sanitizePhoneNumber(rawPhone);
    if (phone.length != 10) {
      return WhatsAppRateLimitStatus(
        isAllowed: false,
        cooldownSeconds: 0,
        lockoutRemainingMinutes: 0,
        attemptsRemaining: 0,
        message: 'Please enter a valid 10-digit mobile number.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Check temporary lockout
    final lockoutUntil = prefs.getInt(_prefKey('lockout_until', phone)) ?? 0;
    if (lockoutUntil > now) {
      final remainingMs = lockoutUntil - now;
      final remainingMins = (remainingMs / 60000).ceil();
      return WhatsAppRateLimitStatus(
        isAllowed: false,
        cooldownSeconds: (remainingMs / 1000).ceil(),
        lockoutRemainingMinutes: remainingMins,
        attemptsRemaining: 0,
        message:
            'Too many requests! To protect verification credits, please wait $remainingMins min(s) or upload your Student ID document instead.',
      );
    }

    // 2. Check 24-hour daily limit
    final dailyResetTime = prefs.getInt(_prefKey('daily_reset', phone)) ?? 0;
    var dailyCount = prefs.getInt(_prefKey('daily_count', phone)) ?? 0;
    if (now > dailyResetTime) {
      dailyCount = 0;
      await prefs.setInt(_prefKey('daily_count', phone), 0);
      await prefs.setInt(_prefKey('daily_reset', phone), now + 86400000); // 24 hours
    }

    if (dailyCount >= maxDailyRequests) {
      final hoursRemaining = ((dailyResetTime - now) / 3600000).ceil();
      return WhatsAppRateLimitStatus(
        isAllowed: false,
        cooldownSeconds: 3600,
        lockoutRemainingMinutes: hoursRemaining * 60,
        attemptsRemaining: 0,
        message:
            'Daily WhatsApp OTP limit reached ($maxDailyRequests/$maxDailyRequests). Please upload your Student ID document instead.',
      );
    }

    // 3. Check 1-hour rolling window
    final hourlyResetTime = prefs.getInt(_prefKey('hourly_reset', phone)) ?? 0;
    var hourlyCount = prefs.getInt(_prefKey('hourly_count', phone)) ?? 0;
    if (now > hourlyResetTime) {
      hourlyCount = 0;
      await prefs.setInt(_prefKey('hourly_count', phone), 0);
      await prefs.setInt(_prefKey('hourly_reset', phone), now + 3600000); // 1 hour
    }

    if (hourlyCount >= maxHourlyRequests) {
      // Trigger lockout
      final lockUntil = now + lockoutDuration.inMilliseconds;
      await prefs.setInt(_prefKey('lockout_until', phone), lockUntil);
      return WhatsAppRateLimitStatus(
        isAllowed: false,
        cooldownSeconds: lockoutDuration.inSeconds,
        lockoutRemainingMinutes: lockoutDuration.inMinutes,
        attemptsRemaining: 0,
        message:
            'Maximum hourly OTP attempts reached (3/3). Please wait 30 minutes or upload your Student ID document.',
      );
    }

    // 4. Check sequential cooldown between resends
    final lastSentTime = prefs.getInt(_prefKey('last_sent', phone)) ?? 0;
    final cooldownRequired = _getCooldownForAttempt(hourlyCount);
    final elapsedSec = ((now - lastSentTime) / 1000).floor();
    if (elapsedSec < cooldownRequired) {
      final remaining = cooldownRequired - elapsedSec;
      return WhatsAppRateLimitStatus(
        isAllowed: false,
        cooldownSeconds: remaining,
        lockoutRemainingMinutes: 0,
        attemptsRemaining: maxHourlyRequests - hourlyCount,
        message: 'Please wait $remaining seconds before requesting another code.',
      );
    }

    return WhatsAppRateLimitStatus(
      isAllowed: true,
      cooldownSeconds: 0,
      lockoutRemainingMinutes: 0,
      attemptsRemaining: maxHourlyRequests - hourlyCount,
    );
  }

  /// Progressive cooldown: 1st=60s, 2nd=90s, 3rd=180s
  int _getCooldownForAttempt(int count) {
    if (count == 0) return 60;
    if (count == 1) return 90;
    return 180;
  }

  // ── Send WhatsApp OTP with Credit Protection ────────────────────────────────

  Future<WhatsAppOtpResult> sendOtp(String rawPhone) async {
    final cleanPhone = sanitizePhoneNumber(rawPhone);
    if (cleanPhone.length != 10) {
      return WhatsAppOtpResult(
        isSuccess: false,
        message: 'Please enter a valid 10-digit mobile number.',
      );
    }

    // 1. Enforce Rate Limiting
    final limitStatus = await checkRateLimit(cleanPhone);
    if (!limitStatus.isAllowed) {
      return WhatsAppOtpResult(
        isSuccess: false,
        message: limitStatus.message,
        cooldownSeconds: limitStatus.cooldownSeconds,
        isLockedOut: limitStatus.lockoutRemainingMinutes > 0,
      );
    }

    // 2. Dispatch OTP via Renflair API
    try {
      final otp = (1000 + Random().nextInt(9000)).toString();

      final url = 'https://whatsapp.renflair.in/V1.php';
      final response = await _dio.get(
        url,
        queryParameters: {
          'API': _apiKey,
          'PHONE': cleanPhone,
          'OTP': otp,
          'COUNTRY': _country,
        },
      );

      debugPrint('Renflair WhatsApp Response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        _activeOtp = otp;
        _activePhone = cleanPhone;
        _otpGeneratedAt = DateTime.now();
        _failedVerifyAttempts = 0;

        // 3. Record attempt into persistent rate limiter
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now().millisecondsSinceEpoch;

        final currentHourly = prefs.getInt(_prefKey('hourly_count', cleanPhone)) ?? 0;
        final currentDaily = prefs.getInt(_prefKey('daily_count', cleanPhone)) ?? 0;

        await prefs.setInt(_prefKey('last_sent', cleanPhone), now);
        await prefs.setInt(_prefKey('hourly_count', cleanPhone), currentHourly + 1);
        await prefs.setInt(_prefKey('daily_count', cleanPhone), currentDaily + 1);

        // Also record to Firestore on current user doc for cross-device abuse tracking
        _recordAttemptToFirestore(cleanPhone);

        final nextCooldown = _getCooldownForAttempt(currentHourly + 1);

        return WhatsAppOtpResult(
          isSuccess: true,
          message: 'OTP sent to WhatsApp +91 $cleanPhone',
          cooldownSeconds: nextCooldown,
        );
      } else {
        return WhatsAppOtpResult(
          isSuccess: false,
          message: 'WhatsApp gateway error. Please try again or upload Student ID.',
        );
      }
    } catch (e) {
      debugPrint('WhatsApp OTP error: $e');
      return WhatsAppOtpResult(
        isSuccess: false,
        message: 'Network error sending WhatsApp OTP. Please try again.',
      );
    }
  }

  void _recordAttemptToFirestore(String cleanPhone) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'last_otp_requested_at': FieldValue.serverTimestamp(),
          'otp_attempts_count': FieldValue.increment(1),
          'last_requested_phone': '+91$cleanPhone',
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  // ── Verify OTP with Brute Force Guard ──────────────────────────────────────

  Future<WhatsAppOtpResult> verifyOtp(String enteredOtp) async {
    final trimmed = enteredOtp.trim();

    if (_activeOtp == null || _activePhone == null || _otpGeneratedAt == null) {
      return WhatsAppOtpResult(
        isSuccess: false,
        message: 'No active OTP request. Please request a new code.',
      );
    }

    if (DateTime.now().difference(_otpGeneratedAt!) > otpValidityDuration) {
      _activeOtp = null;
      return WhatsAppOtpResult(
        isSuccess: false,
        message: 'OTP has expired (valid for 5 mins). Please request a new code.',
      );
    }

    // Check failed attempts
    if (trimmed != _activeOtp) {
      _failedVerifyAttempts++;
      final remaining = maxFailedVerifyAttempts - _failedVerifyAttempts;

      if (_failedVerifyAttempts >= maxFailedVerifyAttempts) {
        // Invalidate active OTP and force 15-minute lock
        _activeOtp = null;
        final prefs = await SharedPreferences.getInstance();
        final lockUntil = DateTime.now().millisecondsSinceEpoch + (15 * 60 * 1000);
        await prefs.setInt(_prefKey('lockout_until', _activePhone!), lockUntil);

        return WhatsAppOtpResult(
          isSuccess: false,
          message:
              'Too many incorrect attempts! For security, this phone is locked for 15 minutes. Please upload your Student ID instead.',
          isLockedOut: true,
          cooldownSeconds: 900,
        );
      }

      return WhatsAppOtpResult(
        isSuccess: false,
        message: 'Incorrect code ($remaining attempts remaining). Check WhatsApp.',
      );
    }

    // Verification Success!
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final formattedPhone = '+91$_activePhone';
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'phone_number': formattedPhone,
          'phone_verified': true,
          'is_verified': true,
          'verification_status': 'approved',
          'phone_verified_at': FieldValue.serverTimestamp(),
          'updated_at': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }

      _activeOtp = null;
      _failedVerifyAttempts = 0;

      return WhatsAppOtpResult(
        isSuccess: true,
        message: 'Account verified successfully via WhatsApp!',
      );
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return WhatsAppOtpResult(
        isSuccess: false,
        message: 'Failed to update profile: $e',
      );
    }
  }

  // ── Helper ─────────────────────────────────────────────────────────────────

  static String sanitizePhoneNumber(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    return digits;
  }
}
