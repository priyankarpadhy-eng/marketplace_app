import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/bike_rental_model.dart';
import '../services/bike_rental_service.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import 'add_bike_screen.dart';

class BikeDetailScreen extends StatefulWidget {
  final BikeListing bike;
  final AppUser currentUser;

  const BikeDetailScreen({super.key, required this.bike, required this.currentUser});

  @override
  State<BikeDetailScreen> createState() => _BikeDetailScreenState();
}

class _BikeDetailScreenState extends State<BikeDetailScreen> {
  final BikeRentalService _bikeService = BikeRentalService();
  int _duration = 1;
  final TextEditingController _phoneController = TextEditingController();

  double get _totalAmount {
    final key = _duration.toString();
    if (widget.bike.customPrices.containsKey(key)) {
      return widget.bike.customPrices[key]!;
    }
    return widget.bike.pricePerHour * _duration;
  }

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.currentUser.phoneNumber;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _confirmRental() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide your phone number")));
      return;
    }

    final request = RentalRequest(
      id: '', // Will be set by Firestore
      bikeId: widget.bike.id,
      bikeTitle: widget.bike.title,
      shopId: widget.bike.shopId,
      renterId: widget.currentUser.id,
      renterName: widget.currentUser.name,
      renterPhone: _phoneController.text,
      durationHours: _duration,
      totalAmount: _totalAmount,
      createdAt: DateTime.now(),
    );

    try {
      await _bikeService.createRentalRequest(request);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Request Sent!"),
            content: const Text("The shop will review your request and contact you soon."),
            actions: [
              TextButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text("OK")),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : Colors.white,
      appBar: AppBar(
        title: Text(widget.bike.shopName, style: GoogleFonts.outfit(fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform Risk Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.red.withOpacity(0.15),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Marketplace is just a platform. Buy or sell at your own risk.",
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.red[200] : Colors.red[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: size.height * 0.35,
              child: Stack(
                children: [
                  Center(
                    child: Hero(
                      tag: 'bike_${widget.bike.id}',
                      child: CachedNetworkImage(
                        imageUrl: widget.bike.images.isNotEmpty ? widget.bike.images.first : '',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8F9FA),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.bike.title,
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          "₹${widget.bike.pricePerHour.toStringAsFixed(2)}/hr",
                          style: GoogleFonts.outfit(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.bike.description,
                    style: GoogleFonts.outfit(color: Colors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  if (widget.currentUser.id == widget.bike.shopId) ...[
                    Text(
                      "Owner Actions",
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text("Edit"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddBikeScreen(
                                    currentUser: widget.currentUser,
                                    editBike: widget.bike,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text("Delete"),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Delete Bike?"),
                                  content: const Text("Are you sure you want to delete this bike?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _bikeService.deleteBike(widget.bike.id);
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  Text(
                    "Specifications",
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: widget.bike.specs.entries.map((entry) {
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(entry.key, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(entry.value.toString(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (widget.bike.customPrices.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      "Special Pricing Offers",
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 45,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: widget.bike.customPrices.entries.map((e) {
                          final isSelected = _duration.toString() == e.key;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _duration = int.parse(e.key);
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.orange : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8F9FA)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? Colors.orange : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "${e.key} Hrs @ ₹${e.value.toStringAsFixed(0)}",
                                  style: GoogleFonts.outfit(
                                    color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    "Select Duration (Hours)",
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _durationButton(Icons.remove, () {
                        if (_duration > 1) setState(() => _duration--);
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text("$_duration", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      _durationButton(Icons.add, () {
                        setState(() => _duration++);
                      }),
                      const Spacer(),
                      Text(
                        "Total: ₹${_totalAmount.toStringAsFixed(2)}",
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Your Phone Number",
                      hintText: "+1 234 567 890",
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: widget.bike.isAvailable ? _confirmRental : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        widget.bike.isAvailable ? "Proceed to Checkout" : "NOT AVAILABLE",
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _durationButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
