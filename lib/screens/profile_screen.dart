import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:market_app/models/app_user.dart';
import 'package:market_app/services/auth_service.dart';
import 'package:market_app/services/storage_service.dart';
import 'package:market_app/theme/app_theme.dart';
import 'package:market_app/providers/user_provider.dart';
import 'package:market_app/screens/permission_manager_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:market_app/services/permission_service.dart';
import 'package:market_app/screens/admin/admin_panel_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:market_app/models/marketplace_item.dart';
import 'package:market_app/services/marketplace_service.dart';
import 'package:market_app/screens/list_product_screen.dart';
import 'shop/shop_setup_screen.dart';
import '../widgets/phone_verification_sheet.dart';
import '../widgets/app_loader.dart';
import '../widgets/verification_badge.dart';
import '../widgets/verification_modal.dart';
import '../widgets/id_card_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final AppUser currentUser;

  const ProfileScreen({super.key, required this.currentUser});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late AppUser _user;
  bool _isEditing = false;
  bool _isLoading = false;
  double? _uploadProgress;
  bool _isUploadingId = false;

  final _nicknameController = TextEditingController();
  final _passoutYearController = TextEditingController();
  final _branchController = TextEditingController();
  final _nameController = TextEditingController();

  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  final MarketplaceService _marketService = MarketplaceService();

  @override
  void initState() {
    super.initState();
    _user = widget.currentUser;
    _nicknameController.text = _user.nickname ?? '';
    _passoutYearController.text = _user.passoutYear ?? '';
    _branchController.text = _user.branch ?? '';
    _nameController.text = _user.name;
  }

  Future<void> _pickImage() async {
    final granted = await PermissionService.requestGalleryPermission(context);
    if (!granted) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final String url = await _storageService.uploadFile(File(image.path), folder: 'profiles');
      final updatedUser = _user.copyWith(profileImage: url);
      await AuthService.instance.updateUserProfile(updatedUser);
      setState(() {
        _user = updatedUser;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _pickIdCard() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.surfaceAlt(true) : AppTheme.surface(false),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a picture'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    bool granted = false;
    if (source == ImageSource.camera) {
      granted = await PermissionService.requestCameraPermission(context);
    } else {
      granted = await PermissionService.requestGalleryPermission(context);
    }
    if (!granted) return;

    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() { _isUploadingId = true; _uploadProgress = 0.0; });
    try {
      final String url = await _storageService.uploadFile(
        File(image.path), 
        folder: 'id_cards',
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );
      final updatedUser = _user.copyWith(idCardImage: url);
      await AuthService.instance.updateUserProfile(updatedUser);
      setState(() {
        _user = updatedUser;
        _isUploadingId = false;
        _uploadProgress = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID Card uploaded successfully!')));
    } catch (e) {
      setState(() { _isUploadingId = false; _uploadProgress = null; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final updatedUser = _user.copyWith(
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        passoutYear: _passoutYearController.text.trim(),
        branch: _branchController.text.trim(),
      );
      await AuthService.instance.updateUserProfile(updatedUser);
      setState(() {
        _user = updatedUser;
        _isEditing = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (userState.isLoading) {
      return Scaffold(backgroundColor: AppTheme.scaffoldBg(isDark), body: const AppLoader());
    }

    final currentUser = userState.currentUser;
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBg(isDark),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, size: 48, color: AppTheme.textSecondary(isDark)),
          const SizedBox(height: 12),
          const Text("User session not found."),
          ElevatedButton(onPressed: () => AuthService.instance.signOut(), child: const Text("Sign Out")),
        ])),
      );
    }

    if (!_isEditing && currentUser != _user) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {
          _user = currentUser;
          _nicknameController.text = _user.nickname ?? '';
          _passoutYearController.text = _user.passoutYear ?? '';
          _branchController.text = _user.branch ?? '';
          _nameController.text = _user.name;
        });
      });
    }

    final themeNotifier = ref.read(themeProvider.notifier);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            pinned: true,
            elevation: 0,
            title: Text(
              currentUser.nickname ?? currentUser.name,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppTheme.textPrimary(isDark)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstaProfileHeader(isDark, currentUser),
                  if (_isEditing) _buildEditForm(),
                  if (currentUser.isAdmin && !_isEditing) _buildAdminFounderCard(currentUser),
                  
                  const SizedBox(height: 24),
                  Text("Verification", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(isDark))),
                  const SizedBox(height: 12),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            VerificationBadge(
                              user: currentUser,
                              size: VerificationBadgeSize.large,
                            ),
                            const Spacer(),
                            if (currentUser.idCardImage != null && currentUser.idCardImage!.isNotEmpty)
                              TextButton.icon(
                                onPressed: () => showIdCardDialog(context, currentUser.id),
                                icon: const Icon(Icons.visibility_outlined, size: 16),
                                label: const Text('View Document'),
                                style: TextButton.styleFrom(
                                  foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                                  textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentUser.isDocumentVerified
                              ? 'Status verified as ${currentUser.isAlumni ? "Alumni" : "Student"}. Your verified tag is visible across rides, marketplace listings, and community posts.'
                              : 'You are currently unverified. Verify your Student ID or Alumni proof to unlock verified status and increase trust across the campus community.',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final updated = await showVerificationModal(context, currentUser: currentUser);
                              if (updated != null && mounted) {
                                setState(() => _user = updated);
                                ref.read(userProvider.notifier).refreshUser();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentUser.isDocumentVerified
                                  ? (isDark ? Colors.white12 : const Color(0xFFF1F5F9))
                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              foregroundColor: currentUser.isDocumentVerified
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? const Color(0xFF0F172A) : Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Text(
                              currentUser.isDocumentVerified ? 'Update Verification Document' : 'Verify Status Now',
                              style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text("Communities", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(isDark))),
                  const SizedBox(height: 12),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceAlt(isDark) : AppTheme.surface(isDark),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border(isDark)),
                      boxShadow: [
                        if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366)),
                          title: const Text("Marketplace WhatsApp Group"),
                          onTap: () { launchUrl(Uri.parse('https://chat.whatsapp.com/D8gagbKfTZIC5JbCusG5dr'), mode: LaunchMode.externalApplication); },
                        ),
                        Divider(height: 1, color: AppTheme.border(isDark)),
                        ListTile(
                          leading: const Icon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366)),
                          title: const Text("Ride Sharing WhatsApp Group"),
                          onTap: () { launchUrl(Uri.parse('https://chat.whatsapp.com/CtbkNZRKoJrEBZo2LLrB4p'), mode: LaunchMode.externalApplication); },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text("Settings", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(isDark))),
                  const SizedBox(height: 12),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceAlt(isDark) : AppTheme.surface(isDark),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border(isDark)),
                      boxShadow: [
                        if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(FontAwesomeIcons.shieldHalved),
                          title: const Text("Safety & Permissions"),
                          onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionManagerScreen())); },
                        ),
                        Divider(height: 1, color: AppTheme.border(isDark)),
                        ListTile(
                          leading: Icon(isDark ? FontAwesomeIcons.sun : FontAwesomeIcons.moon),
                          title: Text(isDark ? "Switch to Light Mode" : "Switch to Dark Mode"),
                          onTap: () { themeNotifier.toggleTheme(!isDark); },
                        ),
                        Divider(height: 1, color: AppTheme.border(isDark)),
                        ListTile(
                          leading: const Icon(FontAwesomeIcons.circleQuestion),
                          title: const Text("Help Center"),
                          onTap: () { launchUrl(Uri.parse('https://igitmarketplace.vercel.app/support'), mode: LaunchMode.inAppWebView); },
                        ),
                        Divider(height: 1, color: AppTheme.border(isDark)),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined),
                          title: const Text("Privacy Policy"),
                          onTap: () { launchUrl(Uri.parse('https://igitmarketplace.vercel.app/privacy'), mode: LaunchMode.inAppWebView); },
                        ),
                        Divider(height: 1, color: AppTheme.border(isDark)),
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: const Text("Terms of Service"),
                          onTap: () { launchUrl(Uri.parse('https://igitmarketplace.vercel.app/terms'), mode: LaunchMode.inAppWebView); },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Developer Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark 
                          ? [AppTheme.darkSurface, AppTheme.darkBg] 
                          : [AppTheme.primarySoft, AppTheme.lightSurfaceAlt],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? AppTheme.border(isDark) : AppTheme.rideAccent.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/developer.jpg',
                            width: 100,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.rideAccent.withOpacity(0.2) : AppTheme.surface(isDark),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "DEVELOPER",
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? AppTheme.primaryDark : AppTheme.rideAccent,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Priyankar Padhy",
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary(isDark),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "43rd Civil Engineering",
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.textSecondary(isDark) : AppTheme.rideAccent,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _buildSocialButton(
                                    icon: FontAwesomeIcons.instagram,
                                    color: const Color(0xFFE4405F),
                                    url: "https://www.instagram.com/priyamnkar?igsh=MW82OHp5NzBxZXRmdA==",
                                  ),
                                  const SizedBox(width: 16),
                                  _buildSocialButton(
                                    icon: FontAwesomeIcons.linkedinIn,
                                    color: const Color(0xFF0A66C2),
                                    url: "https://www.linkedin.com/in/priyankar-padhy-06aa3137a?utm_source=share_via&utm_content=profile&utm_medium=member_android",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetTile(IconData icon, String title, String subtitle, Color color, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary(isDark))),
                  Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary(isDark))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildInstaProfileHeader(bool isDark, AppUser user) {
    // Background palette (adapts light/dark)
    final g1 = isDark ? AppTheme.darkSurface : AppTheme.surface(isDark);
    final g2 = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final cardBg = isDark ? AppTheme.darkSurfaceAlt : AppTheme.lightSurfaceAlt;
    final textColor = AppTheme.textPrimary(isDark);
    final subtextColor = AppTheme.textSecondary(isDark);
    final iconBgColor = isDark ? AppTheme.darkSurfaceAlt : AppTheme.lightSurfaceAlt;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05);
    final avatarRingColor1 = isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.1);
    final avatarRingColor2 = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.02);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Gradient hero card ──────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [g1, g2], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: shadowColor, blurRadius: 20, offset: const Offset(0, 8))],
            border: Border.all(color: AppTheme.border(isDark)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with glow ring
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [avatarRingColor1, avatarRingColor2]),
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 72, height: 72,
                        child: GestureDetector(
                          onTap: _isEditing ? _pickImage : null,
                          child: user.profileImage != null
                              ? CachedNetworkImage(imageUrl: user.profileImage!, fit: BoxFit.cover,
                                  placeholder: (_, __) => CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textSecondary(isDark)),
                                  errorWidget: (_, __, ___) => _buildAvatarFallback(user))
                              : _buildAvatarFallback(user),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name + info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.nickname != null && user.nickname!.isNotEmpty)
                          Text('@${user.nickname}',
                            style: GoogleFonts.poppins(fontSize: 12, color: subtextColor)),
                        if (user.branch != null && user.branch!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(20)),
                            child: Text('${user.branch} · ${user.passoutYear ?? ''}',
                              style: GoogleFonts.poppins(fontSize: 10, color: textColor, fontWeight: FontWeight.w600)),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              VerificationBadge(
                                user: user,
                                size: VerificationBadgeSize.compact,
                                onTap: () async {
                                  final updated = await showVerificationModal(context, currentUser: user);
                                  if (updated != null && mounted) {
                                    setState(() => _user = updated);
                                    ref.read(userProvider.notifier).refreshUser();
                                  }
                                },
                              ),
                              if (user.phoneVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.phone_iphone_rounded, color: AppTheme.success, size: 11),
                                      const SizedBox(width: 3),
                                      Text('PHONE', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.success)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit pencil
                  GestureDetector(
                    onTap: () => setState(() => _isEditing = !_isEditing),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                      child: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded, color: textColor, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Stat chips ──────────────────────────────────────
              Row(children: [
                _buildGlassStatChip(user.id, 'posts', 'Posts', Icons.grid_on_rounded, cardBg),
                const SizedBox(width: 8),
                _buildGlassStatChip(user.id, 'listings', 'Listed', Icons.shopping_bag_rounded, cardBg),
              ]),
            ],
          ),
        ),
        
        if (!user.phoneVerified) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => PhoneVerificationSheet.show(context, onVerified: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phone number verified successfully!'))
              );
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(isDark ? 0.1 : 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.security_rounded, color: AppTheme.warning, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Verify Phone Number', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary(isDark))),
                        Text('Secure your account to sell & rent', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary(isDark))),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.warning),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),

        // ── Action buttons ───────────────────────────────────────
        Row(children: [
          Expanded(
            child: _buildActionPill(
              label: _isEditing ? 'Cancel' : 'Edit Profile',
              icon: _isEditing ? Icons.close_rounded : Icons.edit_rounded,
              bg: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFEDE9FE),
              fg: isDark ? Colors.white : const Color(0xFF5B21B6),
              onTap: () => setState(() => _isEditing = !_isEditing),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildActionPill(
              label: 'Log Out',
              icon: Icons.logout_rounded,
              bg: Colors.red.withOpacity(isDark ? 0.15 : 0.08),
              fg: Colors.red,
              onTap: () => AuthService.instance.signOut(),
            ),
          ),
        ]),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildGlassStatChip(String userId, String collection, String label, IconData icon, Color bg) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final iconColor  = isDark ? Colors.white           : const Color(0xFF5B21B6);
    final countColor = isDark ? Colors.white           : const Color(0xFF1A1A2E);
    final labelColor = isDark ? Colors.white70         : const Color(0xFF6B7280);
    final chipBg     = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFF7C3AED).withOpacity(0.08);
    final chipBorder = isDark ? Colors.white.withOpacity(0.12) : const Color(0xFF7C3AED).withOpacity(0.2);
    String fieldKey = collection == 'posts' ? 'authorId' : (collection == 'listings' ? 'sellerId' : 'ownerId');
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(collection).where(fieldKey, isEqualTo: userId).snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.data?.docs.length ?? 0;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: chipBorder),
            ),
            child: Column(
              children: [
                Icon(icon, color: iconColor, size: 16),
                const SizedBox(height: 4),
                Text('$count', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: countColor)),
                Text(label, style: GoogleFonts.poppins(fontSize: 9, color: labelColor)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionPill({required String label, required IconData icon, required Color bg, required Color fg, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }



  void _showDeveloperDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8, maxWidth: 400),
          child: _buildDeveloperCard(),
        ),
      )
    );
  }

  Widget _buildPostsGrid(String userId, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').where('authorId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text("No posts yet"));
        return GridView.builder(
          padding: const EdgeInsets.only(top: 2, bottom: 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            if (data['image'] != null && data['image'].toString().isNotEmpty) {
              return CachedNetworkImage(imageUrl: data['image'], fit: BoxFit.cover);
            }
            return Container(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(
                  data['content'] ?? '', 
                  maxLines: 4, 
                  overflow: TextOverflow.ellipsis, 
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListingsTab(String userId, bool isDark) {
    return StreamBuilder<List<MarketplaceItem>>(
      stream: FirebaseFirestore.instance.collection('listings')
          .where('sellerId', isEqualTo: userId)
          .snapshots()
          .map((s) => s.docs.map((d) => MarketplaceItem.fromFirestore(d)).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const Center(child: Text("No listings yet"));
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 100),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildMarketplaceItemTile(items[index], isDark),
        );
      },
    );
  }


  Widget _buildDeveloperCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
            : [const Color(0xFFE0E7FF), const Color(0xFFC7D2FE)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark) BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.05 : 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "DEVELOPER",
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Priyankar Padhy",
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                    icon: FontAwesomeIcons.instagram,
                    color: const Color(0xFFE4405F),
                    url: "https://www.instagram.com/priyamnkar?igsh=MW82OHp5NzBxZXRmdA==",
                  ),
                  const SizedBox(width: 16),
                  _buildSocialButton(
                    icon: FontAwesomeIcons.linkedinIn,
                    color: const Color(0xFF0A66C2),
                    url: "https://www.linkedin.com/in/priyankar-padhy-06aa3137a?utm_source=share_via&utm_content=profile&utm_medium=member_android",
                  ),
                  const SizedBox(width: 16),
                  _buildSocialButton(
                    icon: FontAwesomeIcons.whatsapp,
                    color: const Color(0xFF25D366),
                    url: "https://wa.me/918112036717",
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, thickness: 0.5, color: Colors.white24),
              const SizedBox(height: 20),
              Text(
                "🤖 IGIT Marketplace is Live!",
                style: GoogleFonts.outfit(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : const Color(0xFF1E1B4B)
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "➡️ On April 10, 2026, I officially published my first-ever application on the Google Play Store: \"IGIT Marketplace\".\n\n"
                "What started as a personal project has grown into a \"College Super App.\" It’s designed to make campus life easier by allowing students to:\n\n"
                "➡️ Connect & Discuss: A social feed for campus-wide conversations.\n"
                "➡️ Ride Sharing: A simple way to coordinate travel and save on costs.\n"
                "➡️ Buy & Sell: A dedicated marketplace for students to trade items.\n\n"
                "❤️ A huge thanks to the Coding Club, IGIT Sarang (Codex) for their constant support throughout this journey.\n\n"
                "➡️ Coming from a Civil Engineering background, building this wasn't exactly a walk in the park. I’m not looking to switch careers into IT; I simply wanted to understand the \"how\" behind the apps we use every day. In the end, curiosity really is the best teacher.\n\n"
                "➡️ The app is built to be incredibly efficient. Even with a high volume of users (5k DAU), the architecture can keep costs minimal and performance high:\n"
                "Frontend: Built with Flutter & Dart for a smooth cross-platform experience.\n"
                "➡️ Database: Powered by Firebase for real-time updates.\n"
                "➡️ Storage: Using Cloudflare to handle images and videos efficiently.\n"
                "➡️ Reliability: I implemented a dual-database system with Supabase as a fallback to ensure the app stays running even if one service hits a snag.\n\n"
                "➡️ What’s Next?\n"
                "We are currently in the early stages with a small group of users. I’m focusing on refining the experience and polishing the features with regular updates before a full-scale rollout to the entire student body.",
                style: GoogleFonts.outfit(
                  fontSize: 13, 
                  color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({required IconData icon, required Color color, required String url}) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: FaIcon(icon, color: color, size: 18),
      ),
    );
  }



  Widget _buildQuickAction(IconData icon, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          FaIcon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAdminFounderCard(AppUser user) {
    final isFounder = user.isFounder;
    final accentColor = isFounder ? Colors.amber : Colors.blue;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFounder 
            ? [const Color(0xFFB45309), const Color(0xFF92400E)] 
            : [const Color(0xFF1E40AF), const Color(0xFF1E3A8A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(isFounder ? Icons.terminal : Icons.admin_panel_settings, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isFounder ? "FOUNDER ACCESS" : "ADMIN CONTROLS", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  Text("God-mode features unlocked", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isFounder ? "OPEN FOUNDER CONSOLE" : "OPEN ADMIN PANEL", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey)),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, {VoidCallback? onTap, Color? color, bool showChevron = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: (color ?? const Color(0xFF64748B)).withOpacity(0.08),
          child: FaIcon(icon, size: 16, color: color ?? const Color(0xFF64748B)),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey)),
        trailing: showChevron ? const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCBD5E1)) : null,
      ),
    );
  }

  Widget _buildProfileImage(AppUser user) {
    return GestureDetector(
      onTap: _isEditing ? _pickImage : null,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
            child: ClipOval(
              child: SizedBox(
                width: 108,
                height: 108,
                child: user.profileImage != null 
                  ? CachedNetworkImage(
                      imageUrl: user.profileImage!,
                      placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                      errorWidget: (context, url, error) => _buildAvatarFallback(user),
                      fit: BoxFit.cover,
                    )
                  : _buildAvatarFallback(user),
              ),
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.black, size: 16),
              ),
            ),
          if (_isLoading)
            const Positioned.fill(child: Center(child: CircularProgressIndicator(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(AppUser user) {
    return Container(
      color: Colors.white12,
      alignment: Alignment.center,
      child: Text(
        user.name.isEmpty ? "?" : user.name[0], 
        style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Edit Your Profile", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => setState(() => _isEditing = false), child: const Text("Cancel")),
          ],
        ),
        _buildTextField(_nameController, "Full Name"),
        _buildTextField(_nicknameController, "Nickname"),
        _buildTextField(_branchController, "Branch / Major"),
        _buildTextField(_passoutYearController, "Passout Year", keyboardType: TextInputType.number),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }



  Widget _buildMarketplaceItemTile(MarketplaceItem item, bool isDark) {
    final statusColor = item.status == 'available'
        ? const Color(0xFF10B981)
        : item.status == 'sold'
            ? const Color(0xFFEC4899)
            : const Color(0xFFF59E0B);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: statusColor.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: item.image.isNotEmpty
              ? CachedNetworkImage(imageUrl: item.image, width: 52, height: 52, fit: BoxFit.cover)
              : Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.shopping_bag_rounded, color: statusColor, size: 22),
                ),
        ),
        title: Text(item.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13)),
        subtitle: Row(children: [
          Text('₹${item.price.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: const Color(0xFF7C3AED), fontSize: 13)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(item.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w800)),
          ),
        ]),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'delete') {
              _marketService.deleteListing(item.id);
            } else if (val == 'edit') {
              final user = ref.read(userProvider).currentUser;
              if (user != null) Navigator.push(context, MaterialPageRoute(builder: (_) => ListProductScreen(currentUser: user, editItem: item)));
            } else {
              _marketService.updateAvailabilityStatus(item.id, val);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'available', child: Text("Available")),
            const PopupMenuItem(value: 'sold', child: Text("Mark Sold")),
            const PopupMenuItem(value: 'not_available', child: Text("Not Available")),
            const PopupMenuItem(value: 'edit', child: Text("Edit Details")),
            const PopupMenuItem(value: 'delete', child: Text("Delete Listing", style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }



  Widget _buildActionCard(String title, String sub, IconData icon, Color color, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: FaIcon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {

  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 1;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Fully opaque so scrolling content cannot bleed through the pinned tab bar
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tabBar,
          Divider(
            height: 1, thickness: 1,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ],
      ),
    );
  }
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return true;
  }
}
