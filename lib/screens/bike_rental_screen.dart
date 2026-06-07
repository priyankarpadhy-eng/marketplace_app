import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bike_rental_model.dart';
import '../services/bike_rental_service.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import 'bike_detail_screen.dart';

class BikeRentalScreen extends StatefulWidget {
  final AppUser currentUser;

  const BikeRentalScreen({super.key, required this.currentUser});

  @override
  State<BikeRentalScreen> createState() => _BikeRentalScreenState();
}

class _BikeRentalScreenState extends State<BikeRentalScreen> {
  final BikeRentalService _bikeService = BikeRentalService();
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Roadbike', 'Mountain', 'Urban', 'Racing'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Icon(Icons.pedal_bike, size: 28),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Available Rentals",
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<BikeListing>>(
              stream: _bikeService.getAvailableBikes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final bikes = snapshot.data ?? [];
                
                if (bikes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/shop_closed.png',
                          width: 250,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.storefront_outlined,
                            size: 100,
                            color: isDark ? Colors.white24 : Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "No bikes available right now",
                          style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          "All shops are closed",
                          style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: bikes.length,
                  itemBuilder: (context, index) {
                    final bike = bikes[index];
                    return _buildBikeCard(context, bike, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBikeCard(BuildContext context, BikeListing bike, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BikeDetailScreen(bike: bike, currentUser: widget.currentUser))),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topRight,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: IconButton(
                    icon: const Icon(Icons.phone, size: 16, color: Colors.orange),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      try {
                        final shopDoc = await FirebaseFirestore.instance.collection('shops').doc(bike.shopId).get();
                        if (shopDoc.exists) {
                          final phone = shopDoc.data()?['phoneNumber'] ?? '';
                          if (phone.isNotEmpty) {
                            launchUrl(Uri.parse("tel:$phone"));
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Contact unavailable."))
                              );
                            }
                          }
                        }
                      } catch (e) {
                        print("Call error: $e");
                      }
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Hero(
                  tag: 'bike_${bike.id}',
                  child: CachedNetworkImage(
                    imageUrl: bike.images.isNotEmpty ? bike.images.first : '',
                    placeholder: (context, url) => const SizedBox(),
                    errorWidget: (context, url, error) => const Icon(Icons.motorcycle, size: 50),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bike.title,
                    style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "₹",
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          Text(
                            "${bike.pricePerHour.toStringAsFixed(0)}/hr",
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ],
                      ),
                      if (!bike.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "BOOKED",
                            style: GoogleFonts.outfit(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "AVAILABLE",
                            style: GoogleFonts.outfit(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
