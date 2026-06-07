import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionManagerScreen extends StatefulWidget {
  const PermissionManagerScreen({super.key});

  @override
  State<PermissionManagerScreen> createState() => _PermissionManagerScreenState();
}

class _PermissionManagerScreenState extends State<PermissionManagerScreen> with WidgetsBindingObserver {
  Map<Permission, PermissionStatus> _statuses = {};
  bool _isLoading = true;

  final List<Map<String, dynamic>> _displayPermissions = [
    {
      'permission': Permission.storage,
      'name': 'Storage',
      'desc': 'Access local files, images, and videos for posting.',
      'icon': Icons.folder_open_rounded,
    },
    {
      'permission': Permission.camera,
      'name': 'Camera',
      'desc': 'Take photos and videos directly from the app.',
      'icon': Icons.camera_alt_rounded,
    },
    {
      'permission': Permission.photos,
      'name': 'Photos / Gallery',
      'desc': 'Browse your gallery to share campus vibes.',
      'icon': Icons.photo_library_rounded,
    },
    {
      'permission': Permission.notification,
      'name': 'Notifications',
      'desc': 'Stay updated with rides, messages, and events.',
      'icon': Icons.notifications_active_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAll();
    }
  }

  Future<void> _checkAll() async {
    Map<Permission, PermissionStatus> newStatuses = {};
    for (var p in _displayPermissions) {
      newStatuses[p['permission'] as Permission] = await (p['permission'] as Permission).status;
    }
    if (mounted) {
      setState(() {
        _statuses = newStatuses;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggle(Permission p) async {
    final status = _statuses[p];
    
    // If it's already granted, we can't "un-grant" it via code.
    // We must tell the user to do it in settings.
    if (status == PermissionStatus.granted || status == PermissionStatus.permanentlyDenied) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Manage Permission"),
          content: Text(
            status == PermissionStatus.granted 
              ? "To revoke this permission, you must disable it in your system settings."
              : "To enable this permission, you must allow it in your system settings."
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("OPEN SETTINGS")),
          ],
        ),
      ) ?? false;

      if (confirm) {
        await openAppSettings();
      }
      return;
    }
    
    await p.request();
    _checkAll();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Privacy & Permissions", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 32),
              Text(
                "APP PERMISSIONS",
                style: GoogleFonts.outfit(
                  fontSize: 12, 
                  fontWeight: FontWeight.w900, 
                  color: Colors.grey, 
                  letterSpacing: 1.5
                ),
              ),
              const SizedBox(height: 16),
              ..._displayPermissions.map((p) => _buildPermissionTile(p, isDark)),
              const SizedBox(height: 48),
              _buildSafetyNote(isDark),
            ],
          ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.security_rounded, size: 48, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            "Your Privacy Matters",
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Marketplace only asks for permissions when they are strictly necessary for the feature you are using.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(Map<String, dynamic> p, bool isDark) {
    final perm = p['permission'] as Permission;
    final status = _statuses[perm] ?? PermissionStatus.denied;
    final isGranted = status.isGranted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isGranted ? Colors.green : Colors.grey).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(p['icon'], color: isGranted ? Colors.green : Colors.grey, size: 20),
        ),
        title: Text(p['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(p['desc'], style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
        trailing: Switch.adaptive(
          value: isGranted,
          activeColor: Colors.green,
          onChanged: (_) => _toggle(perm),
        ),
      ),
    );
  }

  Widget _buildSafetyNote(bool isDark) {
    return Column(
      children: [
        const Icon(Icons.verified_user_rounded, color: Colors.green, size: 24),
        const SizedBox(height: 12),
        Text(
          "All data is encrypted and handled according to Marketplace Privacy Policy. You can revoke access at any time.",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
