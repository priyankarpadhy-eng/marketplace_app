import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/food_service.dart';
import '../../models/app_user.dart';

class RestaurantStatsPage extends StatelessWidget {
  final AppUser currentUser;
  const RestaurantStatsPage({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final foodSvc = FoodService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Analytics',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 24, color: isDark ? Colors.white : const Color(0xFF1E293B)),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: foodSvc.getShopStats(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
          }
          final stats = snapshot.data ?? {
            'todayOrders': 0, 
            'todayRevenue': 0.0,
            'totalOrders': 0,
            'totalRevenue': 0.0
          };
          return ListView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            children: [
              Text(
                "TODAY'S OVERVIEW",
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: "Orders",
                      value: "${stats['todayOrders']}",
                      icon: FontAwesomeIcons.bagShopping,
                      colors: [const Color(0xFF6366F1), const Color(0xFF818CF8)],
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: "Revenue",
                      value: "₹${stats['todayRevenue'].toStringAsFixed(0)}",
                      icon: FontAwesomeIcons.wallet,
                      colors: [const Color(0xFF10B981), const Color(0xFF34D399)],
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              Text(
                "REVENUE TREND",
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              Container(
                height: 240,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Weekly Performance', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Icon(Icons.show_chart_rounded, color: Color(0xFF6366F1)),
                      ],
                    ),
                    const Spacer(),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          Text(
                            'Live data being processed...',
                            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              
              Text(
                "LIFETIME PERFORMANCE",
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              _buildMetricTile(FontAwesomeIcons.chartLine, "Total Revenue", "₹${stats['totalRevenue'].toStringAsFixed(0)}", Colors.purple, isDark),
              _buildMetricTile(FontAwesomeIcons.boxOpen, "Total Orders", "${stats['totalOrders']}", Colors.orange, isDark),
              
              const SizedBox(height: 32),
              Text(
                "QUALITY METRICS",
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              _buildMetricTile(FontAwesomeIcons.star, "Customer Rating", "4.8/5.0", Colors.amber, isDark),
              _buildMetricTile(FontAwesomeIcons.clock, "Avg Prep Time", "18 mins", Colors.blue, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricTile(IconData icon, String title, String value, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: FaIcon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 16),
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white70 : Colors.black87)),
          const Spacer(),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> colors;
  final bool isDark;

  const _StatCard({required this.title, required this.value, required this.icon, required this.colors, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 24),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
          ),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.8), letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}
