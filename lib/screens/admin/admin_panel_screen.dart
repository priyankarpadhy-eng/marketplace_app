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

    // Filter pages based on permissions
    final List<AdminPage> pages = [
      AdminPage("Dashboard", FontAwesomeIcons.chartLine, _buildDashboardTab()),
      AdminPage("Feed", FontAwesomeIcons.bolt, _buildPostsTab()),
      AdminPage("Market", FontAwesomeIcons.shop, _buildMarketTab()),
      AdminPage("Flags", FontAwesomeIcons.flag, _buildManagementTab("Flagged Content", Icons.flag_rounded)),
      if (isFounder) AdminPage("User Roles", FontAwesomeIcons.userShield, _buildRoleManagerTab()),
      if (isFounder) AdminPage("Verifications", FontAwesomeIcons.certificate, _buildShopVerificationsTab()),
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
      drawer: isMobile ? Drawer(child: _buildSidebar(pages, isDark, true)) : null,
      body: Row(
        children: [
          // Custom Sidebar (only on desktop)
          if (!isMobile) _buildSidebar(pages, isDark, false),
          
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

  Widget _buildSidebar(List<AdminPage> pages, bool isDark, bool isDrawer) {
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
                "FOUNDER CONSOLE",
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

  Widget _buildShopVerificationsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppTheme.surface(isDark);

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
                Text("No pending verifications", style: GoogleFonts.outfit(fontSize: 18, color: AppTheme.textSecondary(isDark))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final shop = users[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop Images Carousel-like Grid
                  if (shop.shopImages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                  ],
                  
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(16),
                      itemCount: shop.shopImages.length,
                      itemBuilder: (context, imgIndex) => Container(
                        width: 240,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(shop.shopImages[imgIndex]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(shop.shopName ?? "Untitled Shop", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.textPrimary(isDark))),
                                  Text("Owner: ${shop.name} • ${shop.email}", style: TextStyle(color: AppTheme.textSecondary(isDark), fontSize: 13)),
                                ],
                              ),
                            ),
                            _buildVerificationBadge('PENDING'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(Icons.location_on_outlined, shop.shopAddress ?? "No address", isDark),
                        _buildInfoRow(Icons.phone_outlined, shop.phoneNumber, isDark),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text("Actions:", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textSecondary(isDark))),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildApprovalButton(
                              label: "Approve Shop",
                              icon: FontAwesomeIcons.circleCheck,
                              color: AppTheme.success,
                              onPressed: () => _approveShop(shop.id, ['marketplace', 'rental']),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => _adminService.updateVerificationStatus(shop.id, isVerified: false, status: 'rejected'),
                          icon: Icon(Icons.close, size: 16, color: AppTheme.error),
                          label: Text("Reject Request", style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVerificationBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary(isDark)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: AppTheme.textPrimary(isDark), fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildApprovalButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: FaIcon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
