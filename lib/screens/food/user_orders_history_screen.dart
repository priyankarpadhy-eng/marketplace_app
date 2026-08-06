import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/food_models.dart';
import '../../services/food_service.dart';
import '../../models/app_user.dart';
import '../../theme/app_theme.dart';

class UserOrdersHistoryScreen extends StatelessWidget {
  final AppUser currentUser;
  const UserOrdersHistoryScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final foodSvc = FoodService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(isDark),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'My Food Orders',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 24, color: AppTheme.textPrimary(isDark)),
        ),
      ),
      body: StreamBuilder<List<FoodOrder>>(
        stream: foodSvc.getUserOrders(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.bowlFood, size: 64, color: AppTheme.textSecondary(isDark).withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('No orders yet', style: GoogleFonts.outfit(color: AppTheme.textSecondary(isDark), fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Your delicious meals will show up here!', style: GoogleFonts.outfit(color: AppTheme.textSecondary(isDark).withOpacity(0.6), fontSize: 14)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _HistoryOrderCard(order: orders[index], isDark: isDark);
            },
          );
        },
      ),
    );
  }
}

class _HistoryOrderCard extends StatelessWidget {
  final FoodOrder order;
  final bool isDark;
  const _HistoryOrderCard({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: FaIcon(FontAwesomeIcons.utensils, color: statusColor, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.shopName, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(
                        'Order #${order.dailyOrderNumber ?? '---'} · ${_formatDate(order.createdAt)}',
                        style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary(isDark), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    order.status.toString().split('.').last.toUpperCase(),
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('${item.quantity}x', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.name, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600))),
                    Text('₹${item.price * item.quantity}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              )).toList(),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL PAID', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textSecondary(isDark))),
                Text('₹${order.totalAmount}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: statusColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (order.status) {
      case OrderStatus.new_order: return AppTheme.primary;
      case OrderStatus.confirmed: return Colors.orange;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
