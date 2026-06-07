import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/marketplace_item.dart';
import '../theme/app_theme.dart';



class ListingCard extends StatelessWidget {
  final MarketplaceItem item;
  final VoidCallback? onTap;
  final int index;

  const ListingCard({super.key, required this.item, this.onTap, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg  = AppTheme.surface(isDark);
    final isAvailable  = item.status == 'available';
    final isSold       = item.status == 'sold';
    final priceStr     = '₹${item.price.toStringAsFixed(0)}';
    final accentColor  = AppTheme.accent(isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.border(isDark),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Image area (square top portion) ─────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Product image
                  item.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _PlaceholderBox(isDark: isDark),
                          errorWidget: (_, __, ___) => _PlaceholderBox(isDark: isDark),
                        )
                      : _PlaceholderBox(isDark: isDark),

                  // Sold/N-A overlay tint
                  if (!isAvailable)
                    Container(
                      color: (isSold ? Colors.pink : Colors.orange).withOpacity(0.35),
                    ),

                  // Status badge top-right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _StatusBadge(status: item.status),
                  ),

                  // Condition badge top-left
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.condition.toUpperCase(),
                        style: GoogleFonts.roboto(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info area (bottom portion) ───────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        height: 1.2,
                      ),
                    ),

                    // Price + arrow row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price
                        Text(
                          priceStr,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            height: 1.1,
                          ),
                        ),

                        // Clean arrow
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 16,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ],
                    ),

                    // Seller name
                    Text(
                      'by ${item.sellerName.split(' ').first}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 9,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
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

// ── Status badge ─────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'available') return const SizedBox.shrink();
    final isSold = status == 'sold';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isSold ? AppTheme.error : AppTheme.warning,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isSold ? 'SOLD' : 'N/A',
        style: GoogleFonts.roboto(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Placeholder when no image ─────────────────────────────────────────────
class _PlaceholderBox extends StatelessWidget {
  final bool isDark;
  const _PlaceholderBox({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
      child: Icon(Icons.storefront_rounded,
        size: 36,
        color: isDark ? Colors.white24 : Colors.black12,
      ),
    );
  }
}
