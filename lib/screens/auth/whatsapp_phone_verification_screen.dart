import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_user.dart';
import '../../providers/user_provider.dart';
import '../../services/whatsapp_otp_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_theme.dart';
import 'auth_gate.dart';

class WhatsAppPhoneVerificationScreen extends ConsumerStatefulWidget {
  final AppUser currentUser;

  const WhatsAppPhoneVerificationScreen({
    super.key,
    required this.currentUser,
  });

  @override
  ConsumerState<WhatsAppPhoneVerificationScreen> createState() =>
      _WhatsAppPhoneVerificationScreenState();
}

enum VerificationMethod { whatsappOtp, documentUpload }

class _WhatsAppPhoneVerificationScreenState
    extends ConsumerState<WhatsAppPhoneVerificationScreen> {
  final WhatsAppOtpService _otpService = WhatsAppOtpService.instance;
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  VerificationMethod _selectedMethod = VerificationMethod.whatsappOtp;

  // WhatsApp OTP State
  late final TextEditingController _phoneController;
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  bool _isCodeSent = false;
  bool _isVerifyingOtp = false;
  bool _isSendingOtp = false;
  String? _otpErrorMessage;
  String? _otpSuccessMessage;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  // Document Upload State
  late final TextEditingController _docPhoneController;
  late final TextEditingController _branchController;
  late final TextEditingController _passoutYearController;
  late String _selectedRole; // 'student' or 'alumni'
  File? _pickedDocument;
  bool _isUploadingDoc = false;
  double? _uploadProgress;
  String? _docErrorMessage;

  @override
  void initState() {
    super.initState();
    final initialPhone = widget.currentUser.phoneNumber.isNotEmpty
        ? WhatsAppOtpService.sanitizePhoneNumber(widget.currentUser.phoneNumber)
        : '';
    _phoneController = TextEditingController(text: initialPhone);
    _docPhoneController = TextEditingController(text: initialPhone);
    _branchController = TextEditingController(text: widget.currentUser.branch ?? '');
    _passoutYearController = TextEditingController(text: widget.currentUser.passoutYear ?? '');
    _selectedRole = widget.currentUser.isAlumni ? 'alumni' : 'student';

    if (initialPhone.length == 10) {
      _checkRateLimitOnStart(initialPhone);
    }
  }

  Future<void> _checkRateLimitOnStart(String phone) async {
    final status = await _otpService.checkRateLimit(phone);
    if (!status.isAllowed && status.cooldownSeconds > 0 && mounted) {
      _startCooldown(status.cooldownSeconds);
      if (status.lockoutRemainingMinutes > 0) {
        setState(() => _otpErrorMessage = status.message);
      }
    }
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

  // ── WhatsApp Flow ──────────────────────────────────────────────────────────

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      setState(() => _otpErrorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _otpErrorMessage = null;
      _otpSuccessMessage = null;
    });

    final result = await _otpService.sendOtp(phone);

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _isSendingOtp = false;
        _isCodeSent = true;
        _otpSuccessMessage = 'Code sent to WhatsApp! Check your messages.';
        _pinController.clear();
      });
      _startCooldown(result.cooldownSeconds ?? 60);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _pinFocusNode.requestFocus();
      });
    } else {
      setState(() {
        _isSendingOtp = false;
        _otpErrorMessage = result.message;
      });
      if ((result.cooldownSeconds ?? 0) > 0) {
        _startCooldown(result.cooldownSeconds!);
      }
    }
  }

  Future<void> _handleVerifyOtp([String? codeOverride]) async {
    final code = (codeOverride ?? _pinController.text).trim();
    if (code.length != 4) {
      setState(() => _otpErrorMessage = 'Please enter the complete 4-digit code.');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _otpErrorMessage = null;
    });

    final result = await _otpService.verifyOtp(code);

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _isVerifyingOtp = false;
        _otpSuccessMessage = 'Verification successful! Loading...';
      });

      // Refresh Riverpod state
      await ref.read(userProvider.notifier).refreshUser();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } else {
      setState(() {
        _isVerifyingOtp = false;
        _otpErrorMessage = result.message ?? 'Incorrect code. Please try again.';
      });
    }
  }

  // ── Document Upload Flow ───────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final bool granted;
    if (source == ImageSource.camera) {
      granted = await PermissionService.requestCameraPermission(context);
    } else {
      granted = await PermissionService.requestGalleryPermission(context);
    }

    if (!granted || !mounted) return;

    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (file != null && mounted) {
        setState(() {
          _pickedDocument = File(file.path);
          _docErrorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _docErrorMessage = 'Failed to choose photo: $e');
    }
  }

  void _showImagePickerModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
                title: Text('Take Photo', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
                title: Text('Choose from Gallery', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmitDocument() async {
    final phone = _docPhoneController.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      setState(() => _docErrorMessage = 'Please enter a valid 10-digit contact number.');
      return;
    }

    if (_pickedDocument == null &&
        (widget.currentUser.idCardImage == null || widget.currentUser.idCardImage!.isEmpty)) {
      setState(() => _docErrorMessage = 'Please upload a photo of your ID Card or Degree Certificate.');
      return;
    }

    setState(() {
      _isUploadingDoc = true;
      _uploadProgress = 0.0;
      _docErrorMessage = null;
    });

    try {
      String documentUrl = widget.currentUser.idCardImage ?? '';
      if (_pickedDocument != null) {
        documentUrl = await _storageService.uploadFile(
          _pickedDocument!,
          folder: 'id_cards',
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );
      }

      final updatedUser = widget.currentUser.copyWith(
        phoneNumber: '+91$phone',
        idCardImage: documentUrl,
        role: _selectedRole,
        branch: _branchController.text.trim().isNotEmpty ? _branchController.text.trim() : null,
        passoutYear: _passoutYearController.text.trim().isNotEmpty ? _passoutYearController.text.trim() : null,
        isVerified: false,
        verificationStatus: 'pending',
      );

      await AuthService.instance.updateUserProfile(updatedUser);
      await ref.read(userProvider.notifier).refreshUser();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document submitted! Your account is pending admin verification.'),
          backgroundColor: Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingDoc = false;
          _uploadProgress = null;
          _docErrorMessage = 'Submission failed: $e';
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    await AuthService.instance.signOut();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Student Verification',
          style: GoogleFonts.syne(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: _handleSignOut,
            icon: Icon(Icons.logout_rounded, size: 15, color: textSecondary),
            label: Text(
              'Sign Out',
              style: GoogleFonts.dmSans(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'One-time campus verification',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Verify your account',
                    style: GoogleFonts.syne(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      letterSpacing: -0.02,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete either WhatsApp number verification (instant) or upload your Student ID document.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      height: 1.45,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Segmented Method Switcher ──
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131D31) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Option 1: WhatsApp OTP
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedMethod = VerificationMethod.whatsappOtp);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedMethod == VerificationMethod.whatsappOtp
                                    ? cardBg
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: _selectedMethod == VerificationMethod.whatsappOtp
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FaIcon(FontAwesomeIcons.whatsapp, size: 14, color: Color(0xFF25D366)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'WhatsApp OTP',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedMethod == VerificationMethod.whatsappOtp
                                          ? textPrimary
                                          : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Option 2: Student ID Document
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedMethod = VerificationMethod.documentUpload);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedMethod == VerificationMethod.documentUpload
                                    ? cardBg
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: _selectedMethod == VerificationMethod.documentUpload
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 15,
                                    color: _selectedMethod == VerificationMethod.documentUpload
                                        ? AppTheme.primary
                                        : textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ID Document',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedMethod == VerificationMethod.documentUpload
                                          ? textPrimary
                                          : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Active View ──
                  if (_selectedMethod == VerificationMethod.whatsappOtp)
                    _buildWhatsAppOtpView(
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    )
                  else
                    _buildDocumentUploadView(
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── WhatsApp View Component ───────────────────────────────────────────────

  Widget _buildWhatsAppOtpView({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FaIcon(FontAwesomeIcons.whatsapp, size: 20, color: Color(0xFF25D366)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instant OTP Verification',
                      style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    Text(
                      'Receive a 4-digit code directly on WhatsApp',
                      style: GoogleFonts.dmSans(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Error banner
          if (_otpErrorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _otpErrorMessage!,
                          style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                  ),
                  if (_resendCooldown > 30 || _otpErrorMessage!.contains('limit') || _otpErrorMessage!.contains('locked') || _otpErrorMessage!.contains('ID')) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        setState(() => _selectedMethod = VerificationMethod.documentUpload);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.badge_outlined, size: 13, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Switch to Student ID Document instead',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Success banner
          if (_otpSuccessMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _otpSuccessMessage!,
                      style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF16A34A)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (!_isCodeSent) ...[
            // Mobile Number Input
            Text(
              'Mobile Number',
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    '+91',
                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(width: 10),
                  Container(width: 1, height: 20, color: borderColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Enter 10-digit number',
                        hintStyle: GoogleFonts.dmSans(fontSize: 14, color: textSecondary),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Send OTP button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSendingOtp ? null : _handleSendOtp,
                icon: _isSendingOtp
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                label: Text(
                  _isSendingOtp ? 'Sending...' : 'Send WhatsApp OTP',
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            // OTP Entry View
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Code sent to +91 ${_phoneController.text}',
                  style: GoogleFonts.dmSans(fontSize: 12, color: textSecondary),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isCodeSent = false;
                      _otpErrorMessage = null;
                      _pinController.clear();
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppTheme.rideAccent,
                  ),
                  child: Text('Edit Number', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bulletproof PIN display powered by single controller
            GestureDetector(
              onTap: () => _pinFocusNode.requestFocus(),
              child: Stack(
                children: [
                  // 4 visual boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (i) {
                      final text = _pinController.text;
                      final digit = i < text.length ? text[i] : '';
                      final isFocused = _pinFocusNode.hasFocus && (i == text.length || (i == 3 && text.length == 4));

                      return Container(
                        width: 58,
                        height: 60,
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  // Invisible backing TextField that captures paste, backspace, and typing
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
                onPressed: _isVerifyingOtp ? null : () => _handleVerifyOtp(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: textPrimary,
                  foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isVerifyingOtp
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
                        style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 14),

            Center(
              child: _resendCooldown > 0
                  ? Text(
                      'Resend WhatsApp code in ${_formatCooldown(_resendCooldown)}',
                      style: GoogleFonts.dmSans(fontSize: 12, color: textSecondary),
                    )
                  : TextButton(
                      onPressed: _isSendingOtp ? null : _handleSendOtp,
                      child: Text(
                        'Resend Code via WhatsApp',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF25D366),
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Document Upload View Component ─────────────────────────────────────────

  Widget _buildDocumentUploadView({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.badge_outlined, size: 20, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'College ID Verification',
                      style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    Text(
                      'Upload student ID or degree certificate',
                      style: GoogleFonts.dmSans(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Error banner
          if (_docErrorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _docErrorMessage!,
                      style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Role Switcher: Student vs Alumni
          Text('Status', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Current Student')),
                  selected: _selectedRole == 'student',
                  onSelected: (val) {
                    if (val) setState(() => _selectedRole = 'student');
                  },
                  labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Alumni')),
                  selected: _selectedRole == 'alumni',
                  onSelected: (val) {
                    if (val) setState(() => _selectedRole = 'alumni');
                  },
                  labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Contact Phone Field
          Text('Contact Number', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text('+91', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _docPhoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Enter 10-digit number',
                      hintStyle: GoogleFonts.dmSans(fontSize: 13, color: textSecondary),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Document photo picker box
          Text(
            _selectedRole == 'student' ? 'Student ID Card Photo' : 'Degree / Alumni Proof Photo',
            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _isUploadingDoc ? null : _showImagePickerModal,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _pickedDocument != null ? AppTheme.primary : borderColor,
                  width: _pickedDocument != null ? 1.5 : 1.0,
                ),
              ),
              child: _pickedDocument != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_pickedDocument!, fit: BoxFit.cover),
                          Container(color: Colors.black38),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, size: 14, color: Colors.greenAccent),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Change Photo',
                                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 32, color: textSecondary),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to upload ID Card',
                          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        Text(
                          'Ensure name & photo are clearly visible',
                          style: GoogleFonts.dmSans(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Upload Progress indicator
          if (_isUploadingDoc && _uploadProgress != null) ...[
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: borderColor,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 12),
          ],

          // Submit Document Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isUploadingDoc ? null : _handleSubmitDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: textPrimary,
                foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isUploadingDoc
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    )
                  : Text(
                      'Submit Document for Review',
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
