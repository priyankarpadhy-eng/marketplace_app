import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';
import 'phone_verification_sheet.dart';

Future<AppUser?> showVerificationModal(BuildContext context, {required AppUser currentUser}) {
  return showModalBottomSheet<AppUser>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => VerificationModalContent(currentUser: currentUser),
  );
}

class VerificationModalContent extends StatefulWidget {
  final AppUser currentUser;

  const VerificationModalContent({super.key, required this.currentUser});

  @override
  State<VerificationModalContent> createState() => _VerificationModalContentState();
}

class _VerificationModalContentState extends State<VerificationModalContent> {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  late final TextEditingController _phoneController;
  late String _selectedRole; // 'student' or 'alumni'
  File? _pickedFile;
  bool _isUploading = false;
  double? _uploadProgress;
  String? _errorMessage;
  late bool _isPhoneVerified;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.currentUser.phoneNumber);
    _selectedRole = widget.currentUser.isAlumni ? 'alumni' : 'student';
    _isPhoneVerified = widget.currentUser.phoneVerified;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

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

      if (file != null) {
        setState(() {
          _pickedFile = File(file.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to select image: $e');
    }
  }

  Future<void> _submitVerification() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter your contact phone number.');
      return;
    }

    if (_pickedFile == null && (widget.currentUser.idCardImage == null || widget.currentUser.idCardImage!.isEmpty)) {
      setState(() => _errorMessage = 'Please upload your ID card or verification document.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      String documentUrl = widget.currentUser.idCardImage ?? '';

      if (_pickedFile != null) {
        documentUrl = await _storageService.uploadFile(
          _pickedFile!,
          folder: 'id_cards',
          onProgress: (progress) {
            if (mounted) setState(() => _uploadProgress = progress);
          },
        );
      }

      final updatedUser = widget.currentUser.copyWith(
        phoneNumber: phone,
        idCardImage: documentUrl,
        role: _selectedRole,
        isVerified: false,
        verificationStatus: 'pending',
      );

      await AuthService.instance.updateUserProfile(updatedUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenVerificationPrompt_${widget.currentUser.id}', true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document submitted! Status is now pending review by administrators.'),
          backgroundColor: Color(0xFF0284C7),
        ),
      );
      Navigator.of(context).pop(updatedUser);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = null;
          _errorMessage = 'Upload failed: $e';
        });
      }
    }
  }

  Future<void> _continueUnverified() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenVerificationPrompt_${widget.currentUser.id}', true);

    if (mounted) {
      Navigator.of(context).pop(widget.currentUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final isStudent = _selectedRole == 'student';
    final isPending = widget.currentUser.isPendingVerification;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header Icon & Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campus Verification',
                        style: GoogleFonts.syne(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Submit your phone and documents for admin approval',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Status notice if already pending
            if (isPending)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0C243C) : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF0284C7)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your verification is pending admin review. You can update your phone or document below.',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Role Segmented Switcher (Student vs Alumni)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildRoleTab(
                      title: 'Current Student',
                      icon: Icons.person_rounded,
                      selected: isStudent,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedRole = 'student'),
                    ),
                  ),
                  Expanded(
                    child: _buildRoleTab(
                      title: 'Alumni / Graduate',
                      icon: Icons.school_rounded,
                      selected: !isStudent,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedRole = 'alumni'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Phone Number Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Phone Number',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 18, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter 10-digit mobile number',
                            hintStyle: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (_isPhoneVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                              const SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        TextButton.icon(
                          onPressed: () {
                            PhoneVerificationSheet.show(
                              context,
                              initialPhone: _phoneController.text,
                              onVerified: () {
                                setState(() {
                                  _isPhoneVerified = true;
                                });
                              },
                            );
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.whatsapp,
                            size: 13,
                            color: Color(0xFF25D366),
                          ),
                          label: Text(
                            'Verify OTP',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF25D366),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Requirement note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isStudent
                          ? 'Provide your Student ID Card with name and roll number clearly visible.'
                          : 'Provide proof of graduation (Degree Certificate, Alumni ID, or Provisional).',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        height: 1.4,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Document Upload Area
            GestureDetector(
              onTap: _isUploading ? null : () => _showPickerSheet(context),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _pickedFile != null ? AppTheme.primary : borderColor,
                    width: 1.5,
                  ),
                ),
                child: _pickedFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_pickedFile!, fit: BoxFit.cover),
                            Container(color: Colors.black38),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Change Document',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : widget.currentUser.idCardImage != null && widget.currentUser.idCardImage!.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isPending ? Icons.schedule_rounded : Icons.verified_rounded,
                                  size: 36,
                                  color: isPending ? const Color(0xFF0284C7) : Colors.green,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isPending ? 'Document submitted (Pending review)' : 'Document on file',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap here to replace with a new one',
                                  style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 34,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isStudent ? 'Upload Student ID Card' : 'Upload Alumni Proof',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to choose camera or gallery',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 16),

            // Error message if any
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            // Progress bar if uploading
            if (_isUploading) ...[
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                color: AppTheme.primary,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                _uploadProgress != null
                    ? '${(_uploadProgress! * 100).toInt()}% Uploading...'
                    : 'Processing...',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button
            ElevatedButton(
              onPressed: _isUploading ? null : _submitVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Submit for Verification',
                style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),

            // Skip / Continue as Unverified
            TextButton(
              onPressed: _isUploading ? null : _continueUnverified,
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                'Continue as Unverified',
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTab({
    required String title,
    required IconData icon,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? Colors.white12 : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? Colors.white54 : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? Colors.white54 : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E293B)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text('Take a picture', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text('Choose from gallery', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
