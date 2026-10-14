import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/whatsapp_otp_service.dart';
import '../theme/app_theme.dart';

class PhoneVerificationSheet extends StatefulWidget {
  final VoidCallback onVerified;
  final String? initialPhone;

  const PhoneVerificationSheet({
    super.key,
    required this.onVerified,
    this.initialPhone,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onVerified,
    String? initialPhone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PhoneVerificationSheet(
        onVerified: onVerified,
        initialPhone: initialPhone,
      ),
    );
  }

  @override
  State<PhoneVerificationSheet> createState() => _PhoneVerificationSheetState();
}

class _PhoneVerificationSheetState extends State<PhoneVerificationSheet> {
  final WhatsAppOtpService _otpService = WhatsAppOtpService.instance;
  late final TextEditingController _phoneController;
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  bool _isCodeSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPhone != null && widget.initialPhone!.isNotEmpty
        ? WhatsAppOtpService.sanitizePhoneNumber(widget.initialPhone!)
        : '';
    _phoneController = TextEditingController(text: initial);
    if (initial.length == 10) {
      _checkRateLimitOnStart(initial);
    }
  }

  Future<void> _checkRateLimitOnStart(String phone) async {
    final status = await _otpService.checkRateLimit(phone);
    if (!status.isAllowed && status.cooldownSeconds > 0 && mounted) {
      _startCooldown(status.cooldownSeconds);
      if (status.lockoutRemainingMinutes > 0) {
        setState(() => _errorMessage = status.message);
      }
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _phoneController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  String _formatCooldown(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final result = await _otpService.sendOtp(phone);

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _isLoading = false;
        _isCodeSent = true;
        _successMessage = 'Code sent to WhatsApp! Enter it below.';
        _pinController.clear();
      });
      _startCooldown(result.cooldownSeconds ?? 60);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _pinFocusNode.requestFocus();
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.message;
      });
      if ((result.cooldownSeconds ?? 0) > 0) {
        _startCooldown(result.cooldownSeconds!);
      }
    }
  }

  Future<void> _handleVerifyOtp([String? codeOverride]) async {
    final code = (codeOverride ?? _pinController.text).trim();
    if (code.length != 4) {
      setState(() => _errorMessage = 'Please enter the complete 4-digit code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _otpService.verifyOtp(code);

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() => _isLoading = false);
      widget.onVerified();
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.message ?? 'Incorrect code. Please check WhatsApp.';
      });
      if ((result.cooldownSeconds ?? 0) > 0) {
        _startCooldown(result.cooldownSeconds!);
      }
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title and icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.whatsapp,
                      color: Color(0xFF25D366),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WhatsApp Verification',
                          style: GoogleFonts.syne(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.02,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isCodeSent
                              ? 'Enter the 4-digit code sent to WhatsApp'
                              : 'Verify your phone number instantly via WhatsApp',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Error notification
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Success notification
              if (_successMessage != null && _isCodeSent) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF16A34A)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (!_isCodeSent) ...[
                // Phone number input
                Text(
                  'Mobile Number',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Text(
                        '+91',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(width: 1, height: 20, color: borderColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Enter 10-digit number',
                            hintStyle: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Send OTP Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSendOtp,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                    label: Text(
                      _isLoading ? 'Sending...' : 'Send WhatsApp OTP',
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Phone change row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Code sent to +91 ${_phoneController.text}',
                      style: GoogleFonts.dmSans(fontSize: 13, color: textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isCodeSent = false;
                          _errorMessage = null;
                          _pinController.clear();
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppTheme.rideAccent,
                      ),
                      child: Text(
                        'Edit Number',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Unified PIN boxes (handles typing, paste & backspace seamlessly)
                GestureDetector(
                  onTap: () => _pinFocusNode.requestFocus(),
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (i) {
                          final text = _pinController.text;
                          final digit = i < text.length ? text[i] : '';
                          final isFocused = _pinFocusNode.hasFocus &&
                              (i == text.length || (i == 3 && text.length == 4));

                          return Container(
                            width: 56,
                            height: 58,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isFocused
                                    ? const Color(0xFF25D366)
                                    : (digit.isNotEmpty ? textPrimary : borderColor),
                                width: isFocused ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                digit,
                                style: GoogleFonts.syne(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      Opacity(
                        opacity: 0.0,
                        child: TextField(
                          controller: _pinController,
                          focusNode: _pinFocusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          onChanged: (val) {
                            setState(() {});
                            if (val.length == 4) {
                              _handleVerifyOtp(val);
                            }
                          },
                          decoration: const InputDecoration(counterText: ''),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleVerifyOtp(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textPrimary,
                      foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            ),
                          )
                        : Text(
                            'Verify & Continue',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // Resend OTP cooldown
                Center(
                  child: _resendCooldown > 0
                      ? Text(
                          'Resend code via WhatsApp in ${_formatCooldown(_resendCooldown)}',
                          style: GoogleFonts.dmSans(fontSize: 12, color: textSecondary),
                        )
                      : TextButton(
                          onPressed: _isLoading ? null : _handleSendOtp,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF25D366),
                          ),
                          child: Text(
                            'Resend Code via WhatsApp',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
