import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/food_models.dart';
import '../../services/food_service.dart';
import '../../models/app_user.dart';

class RestaurantMenuSettingsPage extends StatefulWidget {
  final AppUser currentUser;
  const RestaurantMenuSettingsPage({super.key, required this.currentUser});

  @override
  State<RestaurantMenuSettingsPage> createState() => _RestaurantMenuSettingsPageState();
}

class _RestaurantMenuSettingsPageState extends State<RestaurantMenuSettingsPage> {
  final FoodService _foodSvc = FoodService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Shop Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 24, color: isDark ? Colors.white : const Color(0xFF1E293B)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF7C3AED), size: 28),
            onPressed: _showAddCategoryDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildShopStatusSection(isDark),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MENU INVENTORY',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2),
              ),
              GestureDetector(
                onTap: _showAddCategoryDialog,
                child: Text('Add Category', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<FoodCategory>>(
            stream: _foodSvc.getMenu(widget.currentUser.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
              }
              final categories = snapshot.data ?? [];
              if (categories.isEmpty) {
                return _buildEmptyState(isDark);
              }
              return Column(
                children: categories.map((cat) => _CategoryTile(category: cat, shopId: widget.currentUser.id, isDark: isDark)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 48, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No items added yet', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 15)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showAddCategoryDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add Your First Category'),
          ),
        ],
      ),
    );
  }

  Widget _buildShopStatusSection(bool isDark) {
    return StreamBuilder<List<FoodShop>>(
      stream: _foodSvc.getShops(),
      builder: (context, snapshot) {
        final shop = snapshot.data?.firstWhere((s) => s.id == widget.currentUser.id, 
            orElse: () => FoodShop(id: widget.currentUser.id, name: widget.currentUser.shopName ?? 'My Shop', address: widget.currentUser.shopAddress ?? '', phoneNumber: widget.currentUser.phoneNumber, imageUrl: '', status: ShopStatus.closed));
        
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
                  const FaIcon(FontAwesomeIcons.store, size: 16, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 12),
                  Text('Business Availability', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statusButton(ShopStatus.open, 'Open', Colors.green, shop.status),
                  _statusButton(ShopStatus.dineInOnly, 'Dine-In', Colors.orange, shop.status),
                  _statusButton(ShopStatus.closed, 'Closed', Colors.red, shop.status),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(shop.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: _getStatusColor(shop.status)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getStatusMessage(shop.status),
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _getStatusColor(shop.status)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusButton(ShopStatus status, String label, Color color, ShopStatus currentStatus) {
    final active = status == currentStatus;
    return GestureDetector(
      onTap: () => _foodSvc.updateShopStatus(widget.currentUser.id, status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? color : Colors.grey.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  String _getStatusMessage(ShopStatus status) {
    switch (status) {
      case ShopStatus.open: return "Visible to all customers. Accepting orders.";
      case ShopStatus.dineInOnly: return "Visible, but delivery is disabled.";
      case ShopStatus.closed: return "Hidden from market. Not accepting orders.";
    }
  }

  Color _getStatusColor(ShopStatus status) {
    switch (status) {
      case ShopStatus.open: return Colors.green;
      case ShopStatus.dineInOnly: return Colors.orange;
      case ShopStatus.closed: return Colors.red;
    }
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('New Category', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Biriyani, Drinks',
            filled: true,
            fillColor: Colors.grey.withOpacity(0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _foodSvc.addMenuCategory(widget.currentUser.id, controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final FoodCategory category;
  final String shopId;
  final bool isDark;
  const _CategoryTile({required this.category, required this.shopId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: ExpansionTile(
        title: Text(category.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
        leading: const Icon(Icons.category_outlined, color: Color(0xFF7C3AED), size: 20),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        children: [
          if (category.items.isEmpty)
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 20),
               child: Text('No items in this category', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 13)),
             )
          else
            ...category.items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.1) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('₹${item.price}', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(item.isAvailable ? 'Available' : 'Out', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: item.isAvailable ? Colors.green : Colors.red)),
                      const SizedBox(width: 4),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          activeColor: Colors.green,
                          value: item.isAvailable,
                          onChanged: (val) => _toggleAvailability(item, val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Add Item', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF7C3AED)),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleAvailability(FoodItem item, bool val) {
    final newItems = category.items.map((i) {
      if (i.name == item.name) {
        return FoodItem(name: i.name, price: i.price, isAvailable: val, description: i.description, imageUrl: i.imageUrl);
      }
      return i;
    }).toList();
    FoodService().updateMenuCategory(shopId, category.id, {'items': newItems.map((i) => i.toMap()).toList()});
  }

  void _showAddItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Item to ${category.name}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Item Name',
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              decoration: InputDecoration(
                hintText: 'Price',
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                final newItem = FoodItem(name: nameCtrl.text, price: double.parse(priceCtrl.text), isAvailable: true);
                final newItems = [...category.items, newItem];
                FoodService().updateMenuCategory(shopId, category.id, {'items': newItems.map((i) => i.toMap()).toList()});
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }
}
