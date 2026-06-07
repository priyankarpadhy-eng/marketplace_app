import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import '../../models/food_models.dart';
import '../../services/food_service.dart';
import '../../models/app_user.dart';

class FoodMenuScreen extends StatefulWidget {
  final FoodShop shop;
  final AppUser currentUser;
  const FoodMenuScreen({super.key, required this.shop, required this.currentUser});

  @override
  State<FoodMenuScreen> createState() => _FoodMenuScreenState();
}

class _FoodMenuScreenState extends State<FoodMenuScreen> with TickerProviderStateMixin {
  final Map<String, int> _cart = {};
  final FoodService _foodSvc = FoodService();
  String _searchQuery = '';
  TabController? _tabController;
  int _activeCategoryIndex = 0;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _addToCart(String itemName) {
    setState(() {
      _cart[itemName] = (_cart[itemName] ?? 0) + 1;
    });
  }

  void _removeFromCart(String itemName) {
    setState(() {
      if (_cart.containsKey(itemName) && _cart[itemName]! > 0) {
        _cart[itemName] = _cart[itemName]! - 1;
        if (_cart[itemName] == 0) _cart.remove(itemName);
      }
    });
  }

  double _calculateTotal(List<FoodCategory> categories) {
    double total = 0;
    _cart.forEach((itemName, qty) {
      for (var cat in categories) {
        for (var item in cat.items) {
          if (item.name == itemName) {
            total += item.price * qty;
          }
        }
      }
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // Background Mesh Gradient
          _buildMeshGradient(isDark),

          StreamBuilder<List<FoodCategory>>(
            stream: _foodSvc.getMenu(widget.shop.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
              }
              final categories = snapshot.data ?? [];
              
              if (_tabController == null || _tabController!.length != categories.length + 1) {
                _tabController?.dispose();
                _tabController = TabController(length: categories.length + 1, vsync: this);
                _tabController!.addListener(() {
                  if (_tabController!.index != _activeCategoryIndex) {
                    setState(() => _activeCategoryIndex = _tabController!.index);
                  }
                });
              }

              final totalItems = _cart.values.fold(0, (sum, q) => sum + q);
              final totalPrice = _calculateTotal(categories);

              return SafeArea(
                child: Column(
                  children: [
                    _buildHeader(isDark),
                    _buildSearchBar(isDark),
                    _buildCategoryTabs(categories, isDark),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildGrid(categories.expand((c) => c.items).toList(), isDark),
                          ...categories.map((cat) => _buildGrid(cat.items, isDark)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          if (_cart.isNotEmpty)
            StreamBuilder<List<FoodCategory>>(
              stream: _foodSvc.getMenu(widget.shop.id),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                final totalPrice = _calculateTotal(categories);
                return _buildFloatingCart(isDark, categories, totalPrice);
              }
            ),
        ],
      ),
    );
  }

  Widget _buildMeshGradient(bool isDark) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100, right: -100,
              child: _gradientCircle(400, isDark ? const Color(0xFF1E1B4B) : const Color(0xFFD9F99D)),
            ),
            Positioned(
              bottom: -50, left: -100,
              child: _gradientCircle(350, isDark ? const Color(0xFF312E81) : const Color(0xFFBAE6FD)),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientCircle(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.4), color.withOpacity(0)],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          _circularButton(Icons.arrow_back_ios_new_rounded, isDark, () => Navigator.pop(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order From', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                Text(widget.shop.name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
              ],
            ),
          ),
          _circularButton(Icons.notifications_none_rounded, isDark, () {}),
        ],
      ),
    );
  }

  Widget _circularButton(IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search delicious food...',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 56, width: 56,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
            ),
            child: const Icon(Icons.tune_rounded, color: Color(0xFF7C3AED)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(List<FoodCategory> categories, bool isDark) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.transparent,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: [
          _categoryTab('All', _activeCategoryIndex == 0, isDark),
          ...categories.asMap().entries.map((e) => _categoryTab(e.value.name, _activeCategoryIndex == e.key + 1, isDark)),
        ],
      ),
    );
  }

  Widget _categoryTab(String label, bool isSelected, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF7C3AED) : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildGrid(List<FoodItem> items, bool isDark) {
    final filtered = items.where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _EliteFoodCard(
          item: filtered[index],
          quantity: _cart[filtered[index].name] ?? 0,
          onAdd: () => _addToCart(filtered[index].name),
          onRemove: () => _removeFromCart(filtered[index].name),
          isDark: isDark,
          shopOpen: widget.shop.status != ShopStatus.closed,
        );
      },
    );
  }

  Widget _buildFloatingCart(bool isDark, List<FoodCategory> categories, double totalPrice) {
    return Positioned(
      bottom: 24, left: 24, right: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(FontAwesomeIcons.basketShopping, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${_cart.values.fold(0, (s, q) => s + q)} Items', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Check Out', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _handlePlaceOrder(categories, totalPrice),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('ORDER NOW', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handlePlaceOrder(List<FoodCategory> categories, double total) async {
    final orderItems = <OrderItem>[];
    _cart.forEach((itemName, qty) {
      for (var cat in categories) {
        for (var item in cat.items) {
          if (item.name == itemName) {
            orderItems.add(OrderItem(name: item.name, quantity: qty, price: item.price));
          }
        }
      }
    });

    final order = FoodOrder(
      id: '',
      shopId: widget.shop.id,
      shopName: widget.shop.name,
      customerId: widget.currentUser.id,
      customerName: widget.currentUser.name,
      customerPhone: widget.currentUser.phoneNumber,
      customerAddress: widget.currentUser.shopAddress ?? 'Campus Hostel',
      items: orderItems,
      totalAmount: total,
      status: OrderStatus.new_order,
      createdAt: DateTime.now(),
    );

    await _foodSvc.placeOrder(order);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order Placed Successfully! 🍔', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }
}

class _EliteFoodCard extends StatelessWidget {
  final FoodItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool isDark;
  final bool shopOpen;

  const _EliteFoodCard({
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.isDark,
    required this.shopOpen,
  });

  @override
  Widget build(BuildContext context) {
    final available = item.isAvailable && shopOpen;
    final hash = item.name.hashCode;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Part (Price & Favorite)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${item.price.toInt()}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF1E293B))),
                Icon(Icons.favorite_rounded, size: 20, color: Colors.red.withOpacity(0.2)),
              ],
            ),
          ),
          
          // Image
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  Center(
                    child: Hero(
                      tag: 'food_${item.name}',
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.contain, height: 110)
                        : Icon(Icons.fastfood_rounded, size: 60, color: Colors.grey.withOpacity(0.1)),
                    ),
                  ),
                  if (!available)
                    Container(
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(24)),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                          child: Text('SOLD OUT', style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Bottom Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF1E293B))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (quantity == 0)
                      GestureDetector(
                        onTap: available ? onAdd : null,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ),
                      )
                    else
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(onTap: onRemove, child: const Icon(Icons.remove, color: Colors.white, size: 14)),
                              Text('$quantity', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                              GestureDetector(onTap: onAdd, child: const Icon(Icons.add, color: Colors.white, size: 14)),
                            ],
                          ),
                        ),
                      ),
                    if (quantity == 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFD9F99D).withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                        child: Text('10% OFF', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF166534))),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
