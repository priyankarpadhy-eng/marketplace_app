import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/food_models.dart';

class CartBottomSheet extends StatelessWidget {
  final Map<String, CartEntry> cart;
  final Function(CartEntry) onAdd;
  final Function(CartEntry) onRemove;
  final VoidCallback onPlaceOrder;
  final bool isDark;

  const CartBottomSheet({
    super.key,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
    required this.onPlaceOrder,
    required this.isDark,
  });

  double _calculateTotal() {
    double total = 0;
    cart.forEach((itemName, entry) {
      total += entry.item.price * entry.quantity;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    // Premium Minimalist Theme (Linear / Vercel style)
    final bgColor = isDark ? const Color(0xFF111111) : const Color(0xFFFAFAFA);
    final surfaceColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);
    final textColor = isDark ? Colors.white : const Color(0xFF111111);
    final mutedColor = isDark ? Colors.white54 : Colors.black54;

    final itemsList = cart.values.toList();
    final total = _calculateTotal();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                color: mutedColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Cart', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: textColor, letterSpacing: -0.02)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text('${itemsList.length} items', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: textColor)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Items List
          if (itemsList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text("Your cart is empty", style: GoogleFonts.outfit(color: mutedColor, fontSize: 15)),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: itemsList.length,
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: borderColor, height: 1),
                ),
                itemBuilder: (context, index) {
                  final entry = itemsList[index];
                  final item = entry.item;
                  final shop = entry.shop;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Item details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                            const SizedBox(height: 2),
                            Text(shop.name, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: mutedColor)),
                            const SizedBox(height: 8),
                            Text('₹${item.price.toInt()}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
                          ],
                        ),
                      ),
                      // Controls
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => onRemove(entry),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: mutedColor.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
                                child: Icon(Icons.remove, size: 14, color: textColor),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('${entry.quantity}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => onAdd(entry),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: mutedColor.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
                                child: Icon(Icons.add, size: 14, color: textColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          const SizedBox(height: 32),
          // Bill Details
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total to pay', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: mutedColor)),
                Text('₹${total.toInt()}', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: textColor, letterSpacing: -0.5)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Button (Swipe to Confirm)
          if (itemsList.isNotEmpty)
            SwipeToConfirm(
              text: 'SWIPE TO CONFIRM',
              onConfirm: onPlaceOrder,
              isDark: isDark,
            ),
            
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class SwipeToConfirm extends StatefulWidget {
  final VoidCallback onConfirm;
  final String text;
  final bool isDark;
  
  const SwipeToConfirm({super.key, required this.onConfirm, required this.text, required this.isDark});

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm> {
  double _position = 0.0;
  bool _confirmed = false;
  final double _height = 56.0;
  final double _knobSize = 44.0;

  @override
  Widget build(BuildContext context) {
    // Inverted logic:
    // Dark Theme -> Container White, Knob Black, Text Black
    // Light Theme -> Container Black, Knob White, Text White
    final bgColor = widget.isDark ? Colors.white : const Color(0xFF111111);
    final knobColor = widget.isDark ? const Color(0xFF111111) : Colors.white;
    final textColor = widget.isDark ? const Color(0xFF111111) : Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - _knobSize - 12.0;

        return Container(
          height: _height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  _confirmed ? 'Confirmed' : widget.text,
                  style: GoogleFonts.outfit(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: _confirmed ? const Duration(milliseconds: 200) : Duration.zero,
                left: _position + 6.0,
                top: 6.0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_confirmed) return;
                    setState(() {
                      _position += details.delta.dx;
                      if (_position < 0) _position = 0;
                      if (_position > maxDrag) _position = maxDrag;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_confirmed) return;
                    if (_position > maxDrag * 0.75) {
                      setState(() {
                        _position = maxDrag;
                        _confirmed = true;
                      });
                      Future.delayed(const Duration(milliseconds: 300), () {
                        widget.onConfirm();
                      });
                    } else {
                      setState(() {
                        _position = 0;
                      });
                    }
                  },
                  child: Container(
                    height: _knobSize,
                    width: _knobSize,
                    decoration: BoxDecoration(
                      color: knobColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.arrow_forward_rounded, color: bgColor, size: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
