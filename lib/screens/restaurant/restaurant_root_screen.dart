import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/app_user.dart';
import 'orders_page.dart';
import 'stats_page.dart';
import 'menu_page.dart';
import 'settings_page.dart';

class RestaurantRootScreen extends StatefulWidget {
  final AppUser currentUser;
  const RestaurantRootScreen({super.key, required this.currentUser});

  @override
  State<RestaurantRootScreen> createState() => _RestaurantRootScreenState();
}

class _RestaurantRootScreenState extends State<RestaurantRootScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      RestaurantOrdersPage(currentUser: widget.currentUser),
      RestaurantStatsPage(currentUser: widget.currentUser),
      RestaurantMenuPage(currentUser: widget.currentUser),
      RestaurantSettingsPage(currentUser: widget.currentUser),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF1F2937) : Colors.white;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, LucideIcons.clipboardList, 'Orders'),
                _buildNavItem(1, LucideIcons.pieChart, 'Stats'),
                _buildNavItem(2, LucideIcons.utensils, 'Menu'),
                _buildNavItem(3, LucideIcons.settings, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = Color(0xFF4285F4); // Google Blue

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? activeColor : (isDark ? Colors.white38 : Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? activeColor : (isDark ? Colors.white38 : Colors.grey),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
