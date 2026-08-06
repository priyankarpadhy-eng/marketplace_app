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
import '../../models/bike_rental_model.dart';
import '../../services/marketplace_service.dart';
import '../../services/bike_rental_service.dart';
import '../list_product_screen.dart';
import '../add_bike_screen.dart';

class ShopConsoleScreen extends ConsumerStatefulWidget {
  const ShopConsoleScreen({super.key});

  @override
  ConsumerState<ShopConsoleScreen> createState() => _ShopConsoleScreenState();
}

class _ShopConsoleScreenState extends ConsumerState<ShopConsoleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MarketplaceService _marketService = MarketplaceService();
  final BikeRentalService _bikeService = BikeRentalService();

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
        title: Text("My Listings & Requests", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: AppTheme.textSecondary(isDark),
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: "Listings"),
            Tab(text: "Requests"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListingsTab(context, user, isDark),
          _buildRequestsTab(context, user, isDark),
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
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  "Rent Bike",
                  "List Bike Rental",
                  FontAwesomeIcons.motorcycle,
                  Colors.orange,
                  isDark,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddBikeScreen(currentUser: user))),
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
          const SizedBox(height: 24),
          Text("My Rental Bikes", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<List<BikeListing>>(
            stream: _bikeService.getShopBikes(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final bikes = snapshot.data ?? [];
              if (bikes.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("No bikes listed yet."));
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bikes.length,
                itemBuilder: (context, index) {
                  final bike = bikes[index];
                  return _buildBikeItemTile(bike, isDark);
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

  Widget _buildBikeItemTile(BikeListing bike, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.surface(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: bike.images.isNotEmpty ? DecorationImage(image: CachedNetworkImageProvider(bike.images.first), fit: BoxFit.cover) : null,
          ),
          child: bike.images.isEmpty ? const Icon(Icons.motorcycle) : null,
        ),
        title: Text(bike.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("₹${bike.pricePerHour}/hr • ${bike.isAvailable ? 'AVAILABLE' : 'UNAVAILABLE'}"),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'delete') {
              _bikeService.deleteBike(bike.id);
            } else if (val == 'edit') {
              final user = ref.read(userProvider).currentUser;
              if (user != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AddBikeScreen(currentUser: user, editBike: bike)));
              }
            } else {
              _bikeService.updateBikeAvailability(bike.id, val == 'available');
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'available', child: Text("Set Available")),
            const PopupMenuItem(value: 'unavailable', child: Text("Set Unavailable")),
            const PopupMenuItem(value: 'edit', child: Text("Edit Details")),
            const PopupMenuItem(value: 'delete', child: Text("Delete Bike", style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab(BuildContext context, AppUser user, bool isDark) {
    return StreamBuilder<List<RentalRequest>>(
      stream: _bikeService.getShopRequests(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(child: Text("No rental requests yet"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestCard(request, isDark);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(RentalRequest request, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(request.bikeTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildStatusBadge(request.status),
            ],
          ),
          const SizedBox(height: 8),
          Text("Renter: ${request.renterName}", style: GoogleFonts.outfit(color: AppTheme.textSecondary(isDark))),
          Text("Duration: ${request.durationHours} hrs", style: GoogleFonts.outfit(color: AppTheme.textSecondary(isDark))),
          Text("Amount: ₹${request.totalAmount.toStringAsFixed(2)}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: () => launchUrl(Uri.parse("tel:${request.renterPhone}")),
                icon: const Icon(Icons.phone, color: Colors.green),
              ),
              const Spacer(),
              if (request.status == 'pending') ...[
                TextButton(
                  onPressed: () => _bikeService.updateRequestStatus(request.id, 'declined'),
                  child: const Text("Decline", style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () => _bikeService.updateRequestStatus(request.id, 'approved'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text("Approve"),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'approved') color = Colors.green;
    if (status == 'declined') color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
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
