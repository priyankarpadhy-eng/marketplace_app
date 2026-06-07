import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/food_models.dart';
import '../../services/food_service.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import 'shop_profile_page.dart';

class RestaurantSettingsPage extends StatelessWidget {
  final AppUser currentUser;
  const RestaurantSettingsPage({super.key, required this.currentUser});

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
          'Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 24, color: isDark ? Colors.white : const Color(0xFF1E293B)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildShopStatusSection(foodSvc, isDark),
          const SizedBox(height: 32),
          Text(
            'GENERAL',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.restaurant_menu_rounded,
            title: 'Menu Management',
            subtitle: 'Categories, items, and pricing',
            onTap: () {
              // Usually handled by the tab bar in this case, 
              // but we can provide a shortcut if needed.
            },
            isDark: isDark,
          ),
          _buildSettingTile(
            icon: Icons.store_rounded,
            title: 'Shop Profile',
            subtitle: 'Name, address, and contact info',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => RestaurantShopProfilePage(currentUser: currentUser),
            )),
            isDark: isDark,
          ),
          _buildSettingTile(
            icon: Icons.notifications_active_rounded,
            title: 'Notifications',
            subtitle: 'Alerts for new orders',
            onTap: () {},
            isDark: isDark,
          ),
          const SizedBox(height: 32),
          Text(
            'ACCOUNT',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: () => AuthService.instance.signOut(),
            color: Colors.red,
            isDark: isDark,
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'App Version 2.0.0 (Beta)',
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopStatusSection(FoodService foodSvc, bool isDark) {
    return StreamBuilder<List<FoodShop>>(
      stream: foodSvc.getShops(),
      builder: (context, snapshot) {
        final shops = snapshot.data ?? [];
        final shop = shops.firstWhere((s) => s.id == currentUser.id, 
            orElse: () => FoodShop(id: currentUser.id, name: currentUser.shopName ?? 'My Shop', address: currentUser.shopAddress ?? '', phoneNumber: currentUser.phoneNumber, imageUrl: '', status: ShopStatus.closed));
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _getStatusColor(shop.status).withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.power_settings_new_rounded, size: 16, color: _getStatusColor(shop.status)),
                  ),
                  const SizedBox(width: 12),
                  Text('Shop Status', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Spacer(),
                  _buildStatusBadge(shop.status),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statusBtn(context, foodSvc, ShopStatus.open, 'OPEN', Colors.green, shop.status),
                  _statusBtn(context, foodSvc, ShopStatus.dineInOnly, 'DINE-IN', Colors.orange, shop.status),
                  _statusBtn(context, foodSvc, ShopStatus.closed, 'CLOSED', Colors.red, shop.status),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ShopStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.toString().split('.').last.toUpperCase(),
        style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _statusBtn(BuildContext context, FoodService svc, ShopStatus status, String label, Color color, ShopStatus current) {
    final active = status == current;
    return GestureDetector(
      onTap: () => svc.updateShopStatus(currentUser.id, status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: (MediaQuery.of(context).size.width - 120) / 3,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? color : Colors.grey.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: active ? Colors.white : Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, Color? color, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: (color ?? const Color(0xFF7C3AED)).withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color ?? const Color(0xFF7C3AED), size: 20),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      ),
    );
  }

  Color _getStatusColor(ShopStatus status) {
    switch (status) {
      case ShopStatus.open: return Colors.green;
      case ShopStatus.dineInOnly: return Colors.orange;
      case ShopStatus.closed: return Colors.red;
    }
  }
}
