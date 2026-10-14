import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/marketplace_item.dart';
import '../../services/marketplace_service.dart';
import '../list_product_screen.dart';

class ShopConsoleScreen extends ConsumerStatefulWidget {
  const ShopConsoleScreen({super.key});

  @override
  ConsumerState<ShopConsoleScreen> createState() => _ShopConsoleScreenState();
}

class _ShopConsoleScreenState extends ConsumerState<ShopConsoleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MarketplaceService _marketService = MarketplaceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).currentUser;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(isDark),
        foregroundColor: AppTheme.textPrimary(isDark),
        elevation: 0,
        title: Text("My Listings", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: AppTheme.textSecondary(isDark),
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: "Listings"),
            Tab(text: "Orders"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListingsTab(context, user, isDark),
          const Center(child: Text("No orders yet")),
        ],
      ),
    );
  }

  Widget _buildListingsTab(BuildContext context, AppUser user, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  "Sell Product",
                  "Marketplace Item",
                  FontAwesomeIcons.plus,
                  Colors.blue,
                  isDark,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => ListProductScreen(currentUser: user))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text("My Marketplace Items", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<List<MarketplaceItem>>(
            stream: FirebaseFirestore.instance.collection('listings')
                .where('sellerId', isEqualTo: user.id)
                .snapshots()
                .map((s) => s.docs.map((d) => MarketplaceItem.fromFirestore(d)).toList()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final items = snapshot.data ?? [];
              if (items.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("No items listed yet."));
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildMarketplaceItemTile(item, isDark);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplaceItemTile(MarketplaceItem item, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.surface(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: item.image.isNotEmpty ? DecorationImage(image: CachedNetworkImageProvider(item.image), fit: BoxFit.cover) : null,
          ),
          child: item.image.isEmpty ? const Icon(Icons.shopping_bag) : null,
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("₹${item.price} • ${item.status.toUpperCase()}"),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'delete') {
              _marketService.deleteListing(item.id);
            } else if (val == 'edit') {
              final user = ref.read(userProvider).currentUser;
              if (user != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ListProductScreen(currentUser: user, editItem: item)));
              }
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
          color: AppTheme.surface(isDark),
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
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary(isDark))),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(color: AppTheme.textSecondary(isDark), fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
