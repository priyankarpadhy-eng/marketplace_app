import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/bike_rental_model.dart';
import '../services/bike_rental_service.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_bike_screen.dart';

class ShopDashboardScreen extends StatefulWidget {
  final AppUser currentUser;

  const ShopDashboardScreen({super.key, required this.currentUser});

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> with SingleTickerProviderStateMixin {
  final BikeRentalService _bikeService = BikeRentalService();
  late TabController _tabController;
  bool _isShopOpen = true; // Initial value, should ideally be fetched

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Shop Dashboard", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Requests"),
            Tab(text: "My Bikes"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsTab(isDark),
          _buildMyBikesTab(isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddBikeScreen(currentUser: widget.currentUser))),
        label: const Text("Add Bike"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildRequestsTab(bool isDark) {
    return StreamBuilder<List<RentalRequest>>(
      stream: _bikeService.getShopRequests(widget.currentUser.id),
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
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
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
          Text("Renter: ${request.renterName}", style: GoogleFonts.outfit(color: Colors.grey)),
          Text("Duration: ${request.durationHours} hrs", style: GoogleFonts.outfit(color: Colors.grey)),
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

  Widget _buildMyBikesTab(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Shop Status", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              Switch(
                value: _isShopOpen,
                activeColor: Colors.orange,
                onChanged: (val) {
                  setState(() => _isShopOpen = val);
                  _bikeService.toggleShopStatus(widget.currentUser.id, val);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<BikeListing>>(
            stream: _bikeService.getShopBikes(widget.currentUser.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final bikes = snapshot.data ?? [];
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: bikes.length,
                itemBuilder: (context, index) {
                  final bike = bikes[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                      child: bike.images.isNotEmpty ? CachedNetworkImage(imageUrl: bike.images.first) : const Icon(Icons.motorcycle),
                    ),
                    title: Text(bike.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    subtitle: Text("₹${bike.pricePerHour}/hr", style: const TextStyle(color: Colors.orange)),
                    trailing: Switch(
                      value: bike.isAvailable,
                      onChanged: (val) => _bikeService.updateBikeAvailability(bike.id, val),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
