import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import '../../models/food_models.dart';
import '../../services/food_service.dart';
import '../../models/app_user.dart';
import 'user_orders_history_screen.dart';
import '../../widgets/cart_bottom_sheet.dart';
import '../../theme/app_theme.dart';

class FoodShopListScreen extends StatefulWidget {
  final AppUser currentUser;
  const FoodShopListScreen({super.key, required this.currentUser});

  @override
  State<FoodShopListScreen> createState() => _FoodShopListScreenState();
}

class _FoodShopListScreenState extends State<FoodShopListScreen> {
  final FoodService foodSvc = FoodService();
  bool _showShops = false; 
  String _foodCategoryFilter = 'All'; 
  String? _shopFilterId;
  String? _shopFilterName;
  String _searchQuery = '';

  // Cart State
  final Map<String, CartEntry> _cart = {};

  // Streams
  late final Stream<List<FoodShop>> _shopsStream;
  late final Stream<List<Map<String, dynamic>>> _foodsStream;

  @override
  void initState() {
    super.initState();
    _shopsStream = foodSvc.getShops();
    _foodsStream = foodSvc.getAllFoodItems();
  }

  void _addToCart(FoodItem item, FoodShop shop) {
    setState(() {
      final key = '${shop.id}_${item.name}';
      if (_cart.containsKey(key)) {
        _cart[key]!.quantity++;
      } else {
        _cart[key] = CartEntry(item: item, shop: shop, quantity: 1);
      }
    });
  }

  void _removeFromCart(FoodItem item, FoodShop shop) {
    setState(() {
      final key = '${shop.id}_${item.name}';
      if (_cart.containsKey(key)) {
        _cart[key]!.quantity--;
        if (_cart[key]!.quantity <= 0) {
          _cart.remove(key);
        }
      }
    });
  }

  int _getQuantity(FoodItem item, FoodShop shop) {
    final key = '${shop.id}_${item.name}';
    return _cart[key]?.quantity ?? 0;
  }

  double _calculateTotal() {
    return _cart.values.fold(0, (sum, entry) => sum + (entry.item.price * entry.quantity));
  }

  int _calculateTotalItems() {
    return _cart.values.fold(0, (sum, entry) => sum + entry.quantity);
  }

  void _handlePlaceOrder() async {
    // Group by shopId
    final Map<String, List<CartEntry>> itemsByShop = {};
    for (var entry in _cart.values) {
      if (!itemsByShop.containsKey(entry.shop.id)) {
        itemsByShop[entry.shop.id] = [];
      }
      itemsByShop[entry.shop.id]!.add(entry);
    }

    for (var entry in itemsByShop.entries) {
      final shopId = entry.key;
      final shopItems = entry.value;
      final shopName = shopItems.first.shop.name;
      
      final orderItems = shopItems.map((e) => OrderItem(
        name: e.item.name,
        quantity: e.quantity,
        price: e.item.price,
      )).toList();

      final total = shopItems.fold(0.0, (sum, e) => sum + (e.item.price * e.quantity));

      final order = FoodOrder(
        id: '',
        shopId: shopId,
        shopName: shopName,
        customerId: widget.currentUser.id,
        customerName: widget.currentUser.name,
        customerPhone: widget.currentUser.phoneNumber,
        customerAddress: widget.currentUser.shopAddress ?? 'Campus Hostel',
        items: orderItems,
        totalAmount: total,
        status: OrderStatus.new_order,
        createdAt: DateTime.now(),
      );

      await foodSvc.placeOrder(order);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order Placed Successfully! 🍔', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      setState(() {
        _cart.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(isDark),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_shopFilterId != null) {
                            setState(() {
                              _shopFilterId = null;
                              _shopFilterName = null;
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface(isDark),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border(isDark)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary(isDark), size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.surface(isDark),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border(isDark)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: GoogleFonts.poppins(color: AppTheme.textPrimary(isDark), fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Restaurant name, cuisine, or a dish...',
                              hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary(isDark), fontSize: 13),
                              prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
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
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Icon(Icons.receipt_long_rounded, color: AppTheme.textPrimary(isDark), size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Filters Row
                if (_shopFilterId == null)
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

                if (_shopFilterId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$_shopFilterName Menu', 
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(isDark)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                Expanded(
                  child: (_showShops && _shopFilterId == null) ? _buildShopsList(isDark) : _buildFoodsList(isDark),
                ),
              ],
            ),
          ),

          // Floating Cart
          if (_cart.isNotEmpty) _buildFloatingCart(isDark),
        ],
      ),
    );
  }

  Widget _buildShopsList(bool isDark) {
    return StreamBuilder<List<FoodShop>>(
      stream: _shopsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final shops = snapshot.data ?? [];
        if (shops.isEmpty) {
          return Center(child: Text('No restaurants available yet', style: GoogleFonts.poppins(color: AppTheme.textPrimary(isDark))));
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, _cart.isNotEmpty ? 120 : 16),
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
                  _ShopCard(
                    shop: shops[index], 
                    currentUser: widget.currentUser,
                    onTap: () {
                      setState(() {
                        _showShops = false;
                        _shopFilterId = shops[index].id;
                        _shopFilterName = shops[index].name;
                      });
                    },
                  ),
                ],
              );
            }
            return _ShopCard(
              shop: shops[index], 
              currentUser: widget.currentUser,
              onTap: () {
                setState(() {
                  _showShops = false;
                  _shopFilterId = shops[index].id;
                  _shopFilterName = shops[index].name;
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFoodsList(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _foodsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allItems = snapshot.data ?? [];
        
        // Apply filters
        final filteredItems = allItems.where((itemData) {
          final FoodShop shop = itemData['shop'];
          final FoodItem item = itemData['item'];
          final String cat = itemData['category'] as String;

          if (_shopFilterId != null && shop.id != _shopFilterId) return false;
          
          if (_foodCategoryFilter != 'All' && _shopFilterId == null) {
            if (!item.name.toLowerCase().contains(_foodCategoryFilter.toLowerCase()) && 
                !cat.toLowerCase().contains(_foodCategoryFilter.toLowerCase())) {
              return false;
            }
          }

          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            if (!item.name.toLowerCase().contains(query) && !shop.name.toLowerCase().contains(query) && !cat.toLowerCase().contains(query)) {
              return false;
            }
          }

          return true;
        }).toList();

        if (filteredItems.isEmpty) {
          return Center(child: Text('No foods found', style: GoogleFonts.poppins(color: AppTheme.textPrimary(isDark))));
        }

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(16, 16, 16, _cart.isNotEmpty ? 120 : 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.72,
          ),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final data = filteredItems[index];
            final FoodItem item = data['item'];
            final FoodShop shop = data['shop'];
            
            return _FoodItemCard(
              item: item,
              shop: shop,
              quantity: _getQuantity(item, shop),
              onAdd: () => _addToCart(item, shop),
              onRemove: () => _removeFromCart(item, shop),
              isDark: isDark,
            );
          },
        );
      },
    );
  }

  Widget _buildFloatingCart(bool isDark) {
    final totalItems = _calculateTotalItems();
    final totalPrice = _calculateTotal();
    
    // Inverted colors: White in dark theme, Black in light theme
    final bgColor = isDark ? AppTheme.lightSurface : AppTheme.darkBg;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    // Logo part: dark in dark theme (on white bg), bright in bright theme (on black bg)
    final logoBgColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final logoIconColor = isDark ? AppTheme.lightTextPrimary : AppTheme.darkTextPrimary;

    return Positioned(
      bottom: 24, left: 24, right: 24,
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => StatefulBuilder(
              builder: (context, setSheetState) {
                return CartBottomSheet(
                  cart: _cart,
                  isDark: isDark,
                  onAdd: (entry) {
                    _addToCart(entry.item, entry.shop);
                    setSheetState(() {});
                  },
                  onRemove: (entry) {
                    _removeFromCart(entry.item, entry.shop);
                    setSheetState(() {});
                  },
                  onPlaceOrder: () {
                    Navigator.pop(context); // close sheet
                    _handlePlaceOrder();
                  },
                );
              }
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: logoBgColor,
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Icon(FontAwesomeIcons.basketShopping, color: logoIconColor, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$totalItems Items', style: GoogleFonts.outfit(color: textColor.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
                    Text('₹${totalPrice.toInt()}', style: GoogleFonts.outfit(color: textColor, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.warning,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text('View Cart', style: GoogleFonts.outfit(color: AppTheme.darkBg, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.darkBg, size: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  final FoodItem item;
  final FoodShop shop;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool isDark;

  const _FoodItemCard({
    required this.item,
    required this.shop,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final available = item.isAvailable && shop.status != ShopStatus.closed;
    final cardColor = AppTheme.surface(isDark);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border(isDark)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: AppTheme.surfaceAlt(isDark),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.fastfood_rounded, size: 40, color: AppTheme.textSecondary(isDark)),
                  ),
                  if (!available)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.4),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                            child: Text('SOLD OUT', style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6), 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 12),
                          const SizedBox(width: 4),
                          Text('${shop.rating}', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹${item.price.toInt()}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF111111),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Info & Add to Cart
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(isDark),
                    ),
                  ),
                  Text(
                    shop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppTheme.textSecondary(isDark),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.price.toInt()}',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary(isDark),
                        ),
                      ),
                      
                      // Quantity Controls
                      if (quantity == 0)
                        GestureDetector(
                          onTap: available ? onAdd : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.surface(isDark),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.warning.withOpacity(0.5)),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFFFBBF24).withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                              ]
                            ),
                            child: Text('ADD', style: GoogleFonts.outfit(color: AppTheme.warning, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.15), 
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.warning.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(onTap: onRemove, child: Icon(Icons.remove, color: AppTheme.textPrimary(isDark), size: 14)),
                              const SizedBox(width: 8),
                              Text('$quantity', style: GoogleFonts.outfit(color: AppTheme.textPrimary(isDark), fontWeight: FontWeight.w900, fontSize: 13)),
                              const SizedBox(width: 8),
                              GestureDetector(onTap: onAdd, child: Icon(Icons.add, color: AppTheme.textPrimary(isDark), size: 14)),
                            ],
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
    );
  }
}

class _ShopCard extends StatelessWidget {
  final FoodShop shop;
  final AppUser currentUser;
  final VoidCallback onTap;
  
  const _ShopCard({required this.shop, required this.currentUser, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isClosed = shop.status == ShopStatus.closed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppTheme.surface(isDark),
          borderRadius: BorderRadius.circular(24),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                            color: AppTheme.surfaceAlt(isDark),
                            child: Icon(Icons.restaurant_rounded, size: 50, color: AppTheme.textSecondary(isDark)),
                          ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppTheme.surface(isDark), shape: BoxShape.circle),
                    child: Icon(Icons.bookmark_border_rounded, size: 20, color: AppTheme.textSecondary(isDark)),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
                    child: Text('₹50 OFF', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.surface(isDark), borderRadius: BorderRadius.circular(6)),
                    child: Text('30 mins', style: GoogleFonts.poppins(color: AppTheme.textPrimary(isDark), fontSize: 11, fontWeight: FontWeight.w600)),
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
                        decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(6)),
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
                  Divider(height: 1, color: AppTheme.border(isDark)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.eco_rounded, color: AppTheme.success, size: 16),
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
