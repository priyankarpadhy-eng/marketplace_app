import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/food_models.dart';
import '../../services/food_service.dart';
import '../../models/app_user.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import 'package:slide_to_act/slide_to_act.dart';

class RestaurantOrdersPage extends StatefulWidget {
  final AppUser currentUser;
  const RestaurantOrdersPage({super.key, required this.currentUser});

  @override
  State<RestaurantOrdersPage> createState() => _RestaurantOrdersPageState();
}

class _RestaurantOrdersPageState extends State<RestaurantOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final FoodService _foodSvc = FoodService();
  late Stream<List<FoodOrder>> _ordersStream;
  
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _ordersStream = _foodSvc.getShopOrders(widget.currentUser.id);
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 60,
        title: Text(
          'Orders Dashboard',
          style: textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme(!isDark);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or order #',
                prefixIcon: const Icon(LucideIcons.search),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<FoodOrder>>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allOrders = snapshot.data ?? [];
                final filteredOrders = allOrders.where((o) {
                  final nameMatch = o.customerName.toLowerCase().contains(_searchQuery);
                  final idMatch = o.dailyOrderNumber?.toString().contains(_searchQuery) ?? false;
                  return nameMatch || idMatch;
                }).toList();
                
                final newOrders = filteredOrders.where((o) => o.status == OrderStatus.new_order).toList();
                final confirmedOrders = filteredOrders.where((o) => o.status == OrderStatus.confirmed).toList();
                final deliveredOrders = filteredOrders.where((o) => o.status == OrderStatus.delivered).toList();

                return Column(
                  children: [
                    _buildTabBar(newOrders.length, confirmedOrders.length, deliveredOrders.length, isDark),
                    Expanded(
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [
                          _OrderList(orders: newOrders, status: OrderStatus.new_order, isDark: isDark),
                          _OrderList(orders: confirmedOrders, status: OrderStatus.confirmed, isDark: isDark),
                          _OrderList(orders: deliveredOrders, status: OrderStatus.delivered, isDark: isDark),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(int n, int c, int d, bool isDark) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabCtrl,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: isDark ? const Color(0xFF374151) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: isDark ? Colors.white : Colors.black,
        unselectedLabelColor: Colors.grey,
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('NEW'),
                if (n > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF4285F4).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text('$n', style: const TextStyle(color: Color(0xFF4285F4), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ]
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('KITCHEN'),
                if (c > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFBBC05).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text('$c', style: const TextStyle(color: Color(0xFFFBBC05), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ]
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('DONE'),
                if (d > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF34A853).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text('$d', style: const TextStyle(color: Color(0xFF34A853), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatefulWidget {
  final List<FoodOrder> orders;
  final OrderStatus status;
  final bool isDark;
  const _OrderList({required this.orders, required this.status, required this.isDark});

  @override
  State<_OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<_OrderList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.status == OrderStatus.new_order ? LucideIcons.clipboardList : 
              widget.status == OrderStatus.confirmed ? LucideIcons.chefHat : LucideIcons.checkCheck,
              size: 40,
              color: Colors.grey.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No active orders',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: widget.orders.length,
      itemBuilder: (context, index) {
        return _OrderCard(order: widget.orders[index], isDark: widget.isDark, index: index);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final FoodOrder order;
  final bool isDark;
  final int index;
  const _OrderCard({required this.order, required this.isDark, required this.index});

  Future<void> _makeCall() async {
    final url = Uri.parse('tel:${order.customerPhone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodSvc = FoodService();
    final accentColor = _getStatusColor(order.status);
    final textTheme = Theme.of(context).textTheme;
    
    final cardBgColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final topBoxColor = isDark ? accentColor.withOpacity(0.15) : accentColor.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Top Colored Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: topBoxColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Status Badge & Order Number
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${order.dailyOrderNumber?.toString().padLeft(3, '0') ?? '--'}', 
                      style: textTheme.labelSmall?.copyWith(color: isDark ? Colors.white70 : Colors.black54)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cardBgColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _getStatusText(order.status),
                        style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // 2. Name
                Text(order.customerName, 
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
                const SizedBox(height: 8),
                
                // 3. Address
                Text(order.customerAddress, 
                  style: textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                
                // 4. Order List & Total Price
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text('${item.quantity}x', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: accentColor)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.name, style: textTheme.bodyMedium)),
                            Text('${item.price * item.quantity}', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          Text('${order.totalAmount}', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom White Row (Phone & Call Button)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phone', style: textTheme.labelSmall?.copyWith(color: Colors.grey, fontSize: 10)),
                    Text(order.customerPhone, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _makeCall,
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.phone, color: Colors.red, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                if (order.status == OrderStatus.new_order)
                  Expanded(
                    child: SlideAction(
                      height: 48,
                      borderRadius: 100,
                      innerColor: Colors.white,
                      outerColor: const Color(0xFF4285F4),
                      elevation: 0,
                      sliderButtonIconSize: 14,
                      text: 'Slide to Accept',
                      textStyle: textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      onSubmit: () async {
                        await foodSvc.updateOrderStatus(order.id, OrderStatus.confirmed, order.customerId);
                        return null;
                      },
                    ),
                  )
                else if (order.status != OrderStatus.delivered)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => foodSvc.updateOrderStatus(order.id, OrderStatus.delivered, order.customerId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF374151) : Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        minimumSize: const Size(0, 48),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Ready'),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.arrowRight, size: 16),
                        ],
                      ),
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.new_order: return 'NEW';
      case OrderStatus.confirmed: return 'KITCHEN';
      case OrderStatus.delivered: return 'DONE';
      default: return 'UNKNOWN';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.new_order: return const Color(0xFF4285F4);
      case OrderStatus.confirmed: return const Color(0xFFFBBC05);
      case OrderStatus.delivered: return const Color(0xFF34A853);
      default: return Colors.grey;
    }
  }
}
