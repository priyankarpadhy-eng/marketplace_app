import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_service.dart';
import '../../models/post.dart';
import '../../models/marketplace_item.dart';
import '../../models/app_user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
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
    final user = Provider.of<UserProvider>(context).currentUser;
    final isFounder = user?.isFounder ?? false;

    // Filter pages based on permissions
    final List<AdminPage> pages = [
      AdminPage("Dashboard", FontAwesomeIcons.chartLine, _buildDashboardTab()),
      AdminPage("Feed", FontAwesomeIcons.bolt, _buildPostsTab()),
      AdminPage("Market", FontAwesomeIcons.shop, _buildMarketTab()),
      AdminPage("Flags", FontAwesomeIcons.flag, _buildManagementTab("Flagged Content", Icons.flag_rounded)),
      if (isFounder) AdminPage("User Roles", FontAwesomeIcons.userShield, _buildRoleManagerTab()),
      if (isFounder) AdminPage("Verifications", FontAwesomeIcons.certificate, _buildShopVerificationsTab()),
      if (isFounder) AdminPage("System", FontAwesomeIcons.gears, _buildSystemTab()),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
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
        color: const Color(0xFF0F172A),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15)],
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
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
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
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
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
                          FaIcon(page.icon, color: isSelected ? AppTheme.primary : Colors.white60, size: 18),
                          if (!(_isSidebarCollapsed && !isDrawer)) ...[
                            const SizedBox(width: 16),
                            Flexible(
                              child: Text(
                                page.title,
                                style: GoogleFonts.outfit(
                                  color: isSelected ? Colors.white : Colors.white60,
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
          const Divider(color: Colors.white10),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: (_isSidebarCollapsed && !isDrawer) ? 0 : 24),
            leading: (_isSidebarCollapsed && !isDrawer) ? null : const Icon(Icons.logout, color: Colors.redAccent),
            title: (_isSidebarCollapsed && !isDrawer) ? const Icon(Icons.logout, color: Colors.redAccent) : const Text("Exit Console", style: TextStyle(color: Colors.white70)),
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
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
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
                child: Text("F", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold))
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
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
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
                _buildStatCard("Total Users", stats['users'].toString(), FontAwesomeIcons.users, Colors.blue),
                _buildStatCard("Active Listings", stats['listings'].toString(), FontAwesomeIcons.shop, Colors.green),
                _buildStatCard("Daily Posts", stats['posts'].toString(), FontAwesomeIcons.bolt, Colors.orange),
                _buildStatCard("Pending Verifs", stats['pending'].toString(), FontAwesomeIcons.certificate, Colors.purple),
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
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
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
                Icon(Icons.more_vert, color: isDark ? Colors.white38 : Colors.grey),
              ],
            ),
            const SizedBox(height: 20),
            Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
            Text(title, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    },
  );
}

  Widget _buildRoleManagerTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
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
                Text("User Role Manager", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 16),
                TextField(
                  controller: _roleSearchController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  onChanged: (_) => _searchForRole(),
                  decoration: InputDecoration(
                    hintText: "Search by name or email...",
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                    prefixIcon: Icon(Icons.search, color: isDark ? Colors.white60 : Colors.grey),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
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
                    if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
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
      return Center(child: Text("No users found", style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)));
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
                    Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (user.role == 'admin' ? Colors.red : (user.role == 'restaurant' ? Colors.green : (user.role == 'shop' ? Colors.orange : Colors.blue))).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(user.role.toUpperCase(), style: TextStyle(
                  color: user.role == 'admin' ? Colors.red : (user.role == 'restaurant' ? Colors.green : (user.role == 'shop' ? Colors.orange : Colors.blue)),
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
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return StreamBuilder<List<AppUser>>(
      stream: _adminService.watchPendingVerifications(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text("Error loading verifications", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                const FaIcon(FontAwesomeIcons.circleCheck, color: Colors.green, size: 48),
                const SizedBox(height: 16),
                Text("No pending verifications", style: GoogleFonts.outfit(fontSize: 18, color: isDark ? Colors.white70 : Colors.grey)),
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
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
                                  Text(shop.shopName ?? "Untitled Shop", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 22, color: isDark ? Colors.white : Colors.black)),
                                  Text("Owner: ${shop.name} • ${shop.email}", style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                        Text("Actions:", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildApprovalButton(
                              label: "Approve Shop",
                              icon: FontAwesomeIcons.circleCheck,
                              color: Colors.green,
                              onPressed: () => _approveShop(shop.id, ['marketplace', 'rental']),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => _adminService.updateVerificationStatus(shop.id, isVerified: false, status: 'rejected'),
                          icon: const Icon(Icons.close, size: 16, color: Colors.red),
                          label: const Text("Reject Request", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14))),
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
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                            Text(DateFormat.yMMMd().format(post.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                          placeholder: (context, url) => Container(color: Colors.grey.withOpacity(0.1)),
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
                trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _adminService.deleteListing(item.id)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSystemTab() {
    return Center(
      child: Text(
        "System Settings (Coming Soon)",
        style: TextStyle(color: Colors.grey),
      ),
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
