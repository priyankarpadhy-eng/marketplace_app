import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_service.dart';
import '../../models/post.dart';
import '../../models/marketplace_item.dart';
import '../../models/app_user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  final AdminService _adminService = AdminService();
  int _selectedIndex = 0;
  final TextEditingController _roleSearchController = TextEditingController();
  List<AppUser> _searchResults = [];
  bool _isSearchingRole = false;
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _roleSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).currentUser;
    final isFounder = user?.isFounder ?? false;
    final isAdmin = user?.isAdmin ?? false;

    // Filter pages based on permissions
    final List<AdminPage> pages = [
      AdminPage("Dashboard", FontAwesomeIcons.chartLine, _buildDashboardTab()),
      AdminPage("Feed", FontAwesomeIcons.bolt, _buildPostsTab()),
      AdminPage("Market", FontAwesomeIcons.shop, _buildMarketTab()),
      AdminPage("Flags", FontAwesomeIcons.flag, _buildManagementTab("Flagged Content", Icons.flag_rounded)),
      if (isFounder) AdminPage("User Roles", FontAwesomeIcons.userShield, _buildRoleManagerTab()),
      if (isFounder || isAdmin) AdminPage("Verifications", FontAwesomeIcons.certificate, _buildVerificationsTab()),
      if (isFounder) AdminPage("Song Requests", FontAwesomeIcons.music, _buildSongRequestsTab()),
      if (isFounder) AdminPage("System", FontAwesomeIcons.gears, _buildSystemTab()),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.scaffoldBg(isDark);
    final surfaceColor = AppTheme.surface(isDark);
    final textColor = AppTheme.textPrimary(isDark);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      drawer: isMobile ? Drawer(child: _buildSidebar(pages, isDark, true, isFounder)) : null,
      body: Row(
        children: [
          // Custom Sidebar (only on desktop)
          if (!isMobile) _buildSidebar(pages, isDark, false, isFounder),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildHeader(pages[_selectedIndex].title, isDark, surfaceColor, textColor, isMobile),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: pages[_selectedIndex].content,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(List<AdminPage> pages, bool isDark, bool isDrawer, bool isFounder) {
    final width = isDrawer ? 280.0 : (_isSidebarCollapsed ? 80.0 : 260.0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.darkBg,
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: (_isSidebarCollapsed && !isDrawer) ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: (_isSidebarCollapsed && !isDrawer) ? 0 : 24),
            child: Row(
              mainAxisAlignment: (_isSidebarCollapsed && !isDrawer) ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                const FaIcon(FontAwesomeIcons.rocket, color: AppTheme.primary, size: 24),
                if (!(_isSidebarCollapsed && !isDrawer)) ...[
                  const SizedBox(width: 12),
                    Text(
                    "IGIT MARKET",
                    style: GoogleFonts.outfit(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!(_isSidebarCollapsed && !isDrawer))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                isFounder ? "FOUNDER CONSOLE" : "ADMIN CONSOLE",
                style: GoogleFonts.outfit(color: AppTheme.darkTextPrimary.withOpacity(0.38), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final page = pages[index];
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      if (isDrawer) Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: (_isSidebarCollapsed && !isDrawer) ? MainAxisAlignment.center : MainAxisAlignment.start,
                        children: [
                          FaIcon(page.icon, color: isSelected ? AppTheme.primary : AppTheme.darkTextPrimary.withOpacity(0.6), size: 18),
                          if (!(_isSidebarCollapsed && !isDrawer)) ...[
                            const SizedBox(width: 16),
                            Flexible(
                              child: Text(
                                page.title,
                                style: GoogleFonts.outfit(
                                  color: isSelected ? AppTheme.darkTextPrimary : AppTheme.darkTextPrimary.withOpacity(0.6),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(color: AppTheme.darkBorder),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: (_isSidebarCollapsed && !isDrawer) ? 0 : 24),
            leading: (_isSidebarCollapsed && !isDrawer) ? null : Icon(Icons.logout, color: AppTheme.error),
            title: (_isSidebarCollapsed && !isDrawer) ? Icon(Icons.logout, color: AppTheme.error) : Text("Exit Console", style: TextStyle(color: AppTheme.darkTextPrimary.withOpacity(0.7))),
            onTap: () {
              // On mobile/drawer, close drawer first then pop screen
              if (isDrawer) Navigator.of(context).pop(); 
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, bool isDark, Color surfaceColor, Color textColor, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: AppTheme.border(isDark))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (!isMobile) ...[
                  IconButton(
                    icon: Icon(_isSidebarCollapsed ? Icons.menu_open : Icons.menu, color: textColor),
                    onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                  ),
                ] else ...[
                  IconButton(
                    icon: Icon(Icons.menu, color: textColor),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title, 
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: textColor.withOpacity(0.5)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary, 
                child: Text("F", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt(isDark),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: AppTheme.textSecondary(isDark)),
    );
  }

  // --- TAB BUILDERS ---

  Widget _buildDashboardTab() {
    return StreamBuilder<Map<String, int>>(
      stream: _adminService.watchDashboardStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'users': 0, 'listings': 0, 'posts': 0, 'pending': 0};
        
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                _buildStatCard("Total Users", stats['users'].toString(), FontAwesomeIcons.users, AppTheme.primary),
                _buildStatCard("Active Listings", stats['listings'].toString(), FontAwesomeIcons.shop, AppTheme.success),
                _buildStatCard("Daily Posts", stats['posts'].toString(), FontAwesomeIcons.bolt, AppTheme.warning),
                _buildStatCard("Pending Verifs", stats['pending'].toString(), FontAwesomeIcons.certificate, AppTheme.rideAccent),
              ],
            ),
          ],
        );
      }
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 900;
        
        // Calculate card width based on total available width
        double cardWidth;
        if (width > 1200) {
          cardWidth = (constraints.maxWidth - 72) / 4;
        } else if (width > 800) {
          cardWidth = (constraints.maxWidth - 24) / 2;
        } else {
          cardWidth = constraints.maxWidth;
        }

        return Container(
          width: cardWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface(isDark),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: FaIcon(icon, color: color, size: 20),
                ),
                Icon(Icons.more_vert, color: AppTheme.textSecondary(isDark)),
              ],
            ),
            const SizedBox(height: 20),
            Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(isDark))),
            Text(title, style: TextStyle(color: AppTheme.textSecondary(isDark), fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    },
  );
}

  Widget _buildRoleManagerTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppTheme.surface(isDark);
    final query = _roleSearchController.text.trim();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("User Role Manager", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary(isDark))),
                const SizedBox(height: 16),
                TextField(
                  controller: _roleSearchController,
                  style: TextStyle(color: AppTheme.textPrimary(isDark)),
                  onChanged: (_) => _searchForRole(),
                  decoration: InputDecoration(
                    hintText: "Search by name or email...",
                    hintStyle: TextStyle(color: AppTheme.textSecondary(isDark)),
                    prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary(isDark)),
                    filled: true,
                    fillColor: AppTheme.surface(isDark),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border(isDark))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: query.isNotEmpty 
              ? _buildUserList(_searchResults, isDark, surfaceColor)
              : StreamBuilder<List<AppUser>>(
                  stream: _adminService.watchAllUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: AppTheme.error)));
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    return _buildUserList(snapshot.data!, isDark, surfaceColor);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<AppUser> users, bool isDark, Color surfaceColor) {
    if (users.isEmpty) {
      return Center(child: Text("No users found", style: TextStyle(color: AppTheme.textSecondary(isDark))));
    }
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: user.profileImage != null ? CachedNetworkImageProvider(user.profileImage!) : null,
                child: user.profileImage == null ? Text(user.name.isNotEmpty ? user.name[0] : "?") : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(user.email, style: TextStyle(color: AppTheme.textSecondary(isDark), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (user.role == 'admin' ? AppTheme.error : (user.role == 'restaurant' ? AppTheme.success : (user.role == 'shop' ? AppTheme.warning : AppTheme.primary))).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(user.role.toUpperCase(), style: TextStyle(
                  color: user.role == 'admin' ? AppTheme.error : (user.role == 'restaurant' ? AppTheme.success : (user.role == 'shop' ? AppTheme.warning : AppTheme.primary)),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                )),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (role) => _updateRole(user.id, role),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'student', child: Text("Make Student")),
                  const PopupMenuItem(value: 'shop', child: Text("Make Shop")),
                  const PopupMenuItem(value: 'restaurant', child: Text("Make Restaurant")),
                  const PopupMenuItem(value: 'admin', child: Text("Make Admin")),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerificationsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppTheme.surface(isDark);
    final borderColor = AppTheme.border(isDark);

    return StreamBuilder<List<AppUser>>(
      stream: _adminService.watchPendingVerifications(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                const SizedBox(height: 16),
                Text("Error loading verifications", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: Text(snapshot.error.toString(), textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary(isDark), fontSize: 12)),
                ),
                ElevatedButton(onPressed: () => setState(() {}), child: const Text("Retry")),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!;
        
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.circleCheck, color: AppTheme.success, size: 48),
                const SizedBox(height: 16),
                Text("No pending verifications", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(isDark))),
                const SizedBox(height: 6),
                Text("All submitted student, alumni and shop documents have been reviewed.", style: TextStyle(color: AppTheme.textSecondary(isDark), fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final pendingUser = users[index];
            final isShop = pendingUser.isShop || (pendingUser.shopImages.isNotEmpty) || (pendingUser.shopName != null && pendingUser.shopName!.isNotEmpty);
            final hasDocImage = pendingUser.idCardImage != null && pendingUser.idCardImage!.isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: Type Pill + Pending Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isShop ? const Color(0xFFF3E8FF) : (pendingUser.isAlumni ? const Color(0xFFE0E7FF) : const Color(0xFFEFF6FF)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isShop ? 'SHOP APPLICATION' : (pendingUser.isAlumni ? 'ALUMNI VERIFICATION' : 'STUDENT VERIFICATION'),
                            style: GoogleFonts.dmSans(
                              color: isShop ? const Color(0xFF7E22CE) : (pendingUser.isAlumni ? const Color(0xFF4338CA) : const Color(0xFF1D4ED8)),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD97706),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Pending Review',
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFFB45309),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // User identity info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppTheme.surfaceAlt(isDark),
                          backgroundImage: pendingUser.profileImage != null ? CachedNetworkImageProvider(pendingUser.profileImage!) : null,
                          child: pendingUser.profileImage == null
                              ? Text(
                                  pendingUser.name.isNotEmpty ? pendingUser.name[0].toUpperCase() : '?',
                                  style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(isDark)),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isShop ? (pendingUser.shopName ?? pendingUser.name) : pendingUser.name,
                                style: GoogleFonts.syne(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary(isDark)),
                              ),
                              const SizedBox(height: 2),
                              if (isShop && pendingUser.shopSellerName != null)
                                Text('Owner: ${pendingUser.shopSellerName}', style: TextStyle(color: AppTheme.textSecondary(isDark), fontSize: 12)),
                              Text(pendingUser.email, style: TextStyle(color: AppTheme.textSecondary(isDark), fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Phone Number Highlight (The user explicitly requested this!)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 16, color: AppTheme.textSecondary(isDark)),
                          const SizedBox(width: 10),
                          Text('Contact Phone:', style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textSecondary(isDark), fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pendingUser.phoneNumber.isNotEmpty ? pendingUser.phoneNumber : 'Not provided',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: pendingUser.phoneNumber.isNotEmpty ? AppTheme.textPrimary(isDark) : AppTheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Document Preview Section
                    if (!isShop && hasDocImage) ...[
                      Text('Uploaded Verification Document:', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(isDark))),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showDocumentZoomDialog(context, pendingUser.idCardImage!, pendingUser.name),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceAlt(isDark),
                              border: Border.all(color: borderColor),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: pendingUser.idCardImage!,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: 200,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, err) => Center(child: Text('Failed to load document image', style: TextStyle(color: AppTheme.textSecondary(isDark)))),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text('Tap to inspect', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else if (!isShop && !hasDocImage) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceAlt(isDark),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: AppTheme.textSecondary(isDark)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('No document uploaded yet with this submission.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(isDark))),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isShop && pendingUser.shopImages.isNotEmpty) ...[
                      Text('Shop Photos:', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary(isDark))),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: pendingUser.shopImages.length,
                          itemBuilder: (context, imgIndex) => Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(pendingUser.shopImages[imgIndex]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (isShop) {
                                await _approveShop(pendingUser.id, ['marketplace']);
                              } else {
                                await _adminService.updateVerificationStatus(pendingUser.id, isVerified: true, status: 'approved');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Verified ${pendingUser.name} successfully!')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                            label: Text(
                              isShop ? 'Approve Shop' : 'Verify & Approve',
                              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _adminService.updateVerificationStatus(pendingUser.id, isVerified: false, status: 'rejected');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Verification rejected for ${pendingUser.name}')),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFDC2626)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: Text('Reject', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDocumentZoomDialog(BuildContext context, String imageUrl, String userName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Document: $userName',
                      style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const SizedBox(
                      height: 250,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, err) => const SizedBox(
                      height: 200,
                      child: Center(child: Text('Failed to load full image', style: TextStyle(color: Colors.white70))),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pinch to zoom in or inspect document details',
                style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _approveShop(String uid, List<String> tags) async {
    await _adminService.approveShop(uid, tags);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop approved successfully!')));
    }
  }

  // --- REDESIGNED EXISTING TABS ---

  Widget _buildPostsTab() {
    return StreamBuilder<List<Post>>(
      stream: _adminService.watchAllPosts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final post = snapshot.data![index];
            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: AppTheme.surface(isDark),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: post.authorAvatar != null ? CachedNetworkImageProvider(post.authorAvatar!) : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(DateFormat.yMMMd().format(post.createdAt), style: TextStyle(color: AppTheme.textSecondary(isDark), fontSize: 11)),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: AppTheme.error),
                          onPressed: () => _adminService.deletePost(post.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(post.content, style: GoogleFonts.outfit(fontSize: 14)),
                    if (post.image != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: post.image!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppTheme.surfaceAlt(isDark)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMarketTab() {
    return StreamBuilder<List<MarketplaceItem>>(
      stream: _adminService.watchAllListings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CachedNetworkImage(imageUrl: item.image, width: 50, height: 50, fit: BoxFit.cover),
                title: Text(item.title),
                subtitle: Text("${item.priceUnit}${item.price}"),
                trailing: IconButton(icon: Icon(Icons.delete_outline, color: AppTheme.error), onPressed: () => _adminService.deleteListing(item.id)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSystemTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        "System Settings (Coming Soon)",
        style: TextStyle(color: AppTheme.textSecondary(isDark)),
      ),
    );
  }

  Widget _buildSongRequestsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppTheme.surface(isDark);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('song_requests').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text('No song requests yet.', style: TextStyle(color: AppTheme.textSecondary(isDark))));

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final query = data['query'] ?? 'Unknown';
            final requestedByName = data['requestedByName'] ?? 'Unknown User';
            final status = data['status'] ?? 'pending';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: surfaceColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.border(isDark)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.rideAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.music_note, color: AppTheme.rideAccent, size: 20),
                ),
                title: Text('"$query"', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(isDark))),
                subtitle: Text('Requested by $requestedByName', style: TextStyle(color: AppTheme.textSecondary(isDark))),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'resolved' ? AppTheme.success.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status.toUpperCase(), style: TextStyle(
                        color: status == 'resolved' ? AppTheme.success : AppTheme.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      )),
                    ),
                    const SizedBox(width: 8),
                    if (status != 'resolved')
                      IconButton(
                        icon: Icon(Icons.check_circle_outline, color: AppTheme.success),
                        tooltip: "Mark as Resolved",
                        onPressed: () {
                          FirebaseFirestore.instance.collection('song_requests').doc(doc.id).update({'status': 'resolved'});
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildManagementTab(String title, IconData icon) {
    return Center(child: Text(title));
  }

  // --- HELPERS ---

  Future<void> _searchForRole() async {
    final query = _roleSearchController.text.trim();
    if (query.isEmpty) {
      setState(() { _searchResults = []; _isSearchingRole = false; });
      return;
    }
    setState(() => _isSearchingRole = true);
    try {
      final results = await _adminService.searchUsers(query);
      setState(() { _searchResults = results; _isSearchingRole = false; });
    } catch (e) {
      setState(() => _isSearchingRole = false);
    }
  }

  Future<void> _updateRole(String uid, String newRole) async {
    await _adminService.updateUserRole(uid, newRole);
    _searchForRole();
  }


}

class AdminPage {
  final String title;
  final IconData icon;
  final Widget content;
  AdminPage(this.title, this.icon, this.content);
}
