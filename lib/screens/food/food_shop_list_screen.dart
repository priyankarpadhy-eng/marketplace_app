import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/food_models.dart';
import '../../services/food_service.dart';
import 'food_menu_screen.dart';
import '../../models/app_user.dart';
import 'user_orders_history_screen.dart';

import '../../theme/app_theme.dart';

class FoodShopListScreen extends StatefulWidget {
  final AppUser currentUser;
  const FoodShopListScreen({super.key, required this.currentUser});

  @override
  State<FoodShopListScreen> createState() => _FoodShopListScreenState();
}

class _FoodShopListScreenState extends State<FoodShopListScreen> {
  final FoodService foodSvc = FoodService();
  bool _showShops = false; // "first of all we wil show all the foords menu from all resturants"
  String _foodCategoryFilter = 'All'; // e.g. All, Biriyani, Rice, Roti, Noodles

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(isDark),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(isDark),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border(isDark)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary(isDark), size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(isDark),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border(isDark)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: Colors.red.shade400, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Restaurant name, cuisine, or a dish...',
                              style: GoogleFonts.poppins(color: AppTheme.textSecondary(isDark), fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserOrdersHistoryScreen(currentUser: widget.currentUser),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(isDark),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border(isDark)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: AppTheme.textPrimary(isDark), size: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            // Filters Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Filter: Food Type Dropdown
                  PopupMenuButton<String>(
                    onSelected: (String result) {
                      setState(() {
                        _foodCategoryFilter = result;
                      });
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: AppTheme.surface(isDark),
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      for (final type in ['All', 'Biriyani', 'Rice', 'Roti', 'Noodles'])
                        PopupMenuItem<String>(
                          value: type, 
                          child: Text(type, style: GoogleFonts.poppins(color: AppTheme.textPrimary(isDark), fontSize: 13)),
                        ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(isDark),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border(isDark)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant_menu_rounded, size: 14, color: AppTheme.textSecondary(isDark)),
                          const SizedBox(width: 8),
                          Text(
                            _foodCategoryFilter,
                            style: GoogleFonts.poppins(
                              color: AppTheme.textPrimary(isDark),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.textSecondary(isDark)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right Filter: View Toggle Dropdown
                  PopupMenuButton<bool>(
                    onSelected: (bool showShops) {
                      setState(() {
                        _showShops = showShops;
                      });
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: AppTheme.surface(isDark),
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<bool>>[
                      PopupMenuItem<bool>(value: false, child: Text('Foods View', style: GoogleFonts.poppins(color: AppTheme.textPrimary(isDark), fontSize: 13))),
                      PopupMenuItem<bool>(value: true, child: Text('Shops View', style: GoogleFonts.poppins(color: AppTheme.textPrimary(isDark), fontSize: 13))),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(isDark),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border(isDark)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_showShops ? Icons.storefront_rounded : Icons.fastfood_rounded, size: 14, color: AppTheme.textSecondary(isDark)),
                          const SizedBox(width: 8),
                          Text(
                            _showShops ? 'Shops' : 'Foods',
                            style: GoogleFonts.poppins(
                              color: AppTheme.textPrimary(isDark),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.textSecondary(isDark)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: _showShops ? _buildShopsList(isDark) : _buildFoodsList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopsList(bool isDark) {
    return StreamBuilder<List<FoodShop>>(
      stream: foodSvc.getShops(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final shops = snapshot.data ?? [];
        if (shops.isEmpty) {
          return Center(child: Text('No restaurants available yet', style: GoogleFonts.poppins(color: AppTheme.textPrimary(isDark))));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: shops.length,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      '${shops.length} restaurants around you',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary(isDark)),
                    ),
                  ),
                  _ShopCard(shop: shops[index], currentUser: widget.currentUser),
                ],
              );
            }
            return _ShopCard(shop: shops[index], currentUser: widget.currentUser);
          },
        );
      },
    );
  }

  Widget _buildFoodsList(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: foodSvc.getAllFoodItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allItems = snapshot.data ?? [];
        
        // Apply filter
        final filteredItems = allItems.where((itemData) {
          if (_foodCategoryFilter == 'All') return true;
          final itemName = (itemData['item'].name as String).toLowerCase();
          final itemCat = (itemData['category'] as String).toLowerCase();
          final query = _foodCategoryFilter.toLowerCase();
          return itemName.contains(query) || itemCat.contains(query);
        }).toList();

        if (filteredItems.isEmpty) {
          return Center(child: Text('No foods found for $_foodCategoryFilter', style: GoogleFonts.poppins(color: AppTheme.textPrimary(isDark))));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final data = filteredItems[index];
            final FoodItem item = data['item'];
            final FoodShop shop = data['shop'];
            
            return _FoodItemCard(
              item: item,
              shop: shop,
              currentUser: widget.currentUser,
              isDark: isDark,
            );
          },
        );
      },
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  final FoodItem item;
  final FoodShop shop;
  final AppUser currentUser;
  final bool isDark;

  const _FoodItemCard({
    required this.item,
    required this.shop,
    required this.currentUser,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the shop's menu
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => FoodMenuScreen(shop: shop, currentUser: currentUser),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(isDark)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.fastfood_rounded, size: 40, color: isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(isDark),
                      ),
                    ),
                    Text(
                      '₹${item.price}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.storefront_rounded, size: 10, color: AppTheme.textSecondary(isDark)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shop.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppTheme.textSecondary(isDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  final FoodShop shop;
  final AppUser currentUser;
  const _ShopCard({required this.shop, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isClosed = shop.status == ShopStatus.closed;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => FoodMenuScreen(shop: shop, currentUser: currentUser),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppTheme.surface(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border(isDark)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Hero(
                    tag: 'shop_${shop.id}',
                    child: shop.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: shop.imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 200,
                            width: double.infinity,
                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                            child: Icon(Icons.restaurant_rounded, size: 50, color: isDark ? Colors.grey[600] : Colors.grey[300]),
                          ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.bookmark_border_rounded, size: 20, color: Colors.black54),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(6)),
                    child: Text('₹50 OFF', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                    child: Text('30 mins', style: GoogleFonts.poppins(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (isClosed)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                          child: Text('CLOSED', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          shop.name, 
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(isDark)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          children: [
                            Text('${shop.rating}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                            const SizedBox(width: 2),
                            const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          shop.tags.isNotEmpty ? shop.tags.join(', ') : shop.address, 
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary(isDark)),
                        ),
                      ),
                      Text('₹150 for one', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary(isDark))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.eco_rounded, color: Colors.green.shade400, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Funds environmental projects to offset carbon footprint',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary(isDark)),
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

