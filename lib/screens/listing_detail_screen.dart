import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marketplace_item.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../services/marketplace_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'list_product_screen.dart';

const _kPrimary = Color(0xFF7C3AED);
const _kGreen   = Color(0xFF25D366);

class ListingDetailScreen extends ConsumerWidget {
  final MarketplaceItem item;
  const ListingDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(userProvider).currentUser;
    final isOwner = currentUser != null && currentUser.id == item.sellerId;
    final images = item.images.isNotEmpty ? item.images : [item.image];

    final bg      = isDark ? const Color(0xFF0F0E1A) : const Color(0xFFF7F0FF);
    final surface = isDark ? const Color(0xFF1C1B2E) : Colors.white;
    final textPrimary   = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.4),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.4),
              child: IconButton(
                icon: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 18),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Scrollable content ───────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Image gallery ──────────────────────────────
                  _ImageGallery(images: images),

                  // ── Risk banner ────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: Colors.red.withOpacity(isDark ? 0.12 : 0.08),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Marketplace is a platform only. Buy/sell at your own risk.',
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.red.shade200 : Colors.red.shade800,
                            fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ]),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Category + time row ────────────────
                        Row(
                          children: [
                            _Chip(label: item.category.toUpperCase(), color: _kPrimary),
                            const SizedBox(width: 8),
                            _Chip(
                              label: item.condition.toUpperCase(),
                              color: item.condition.toLowerCase() == 'new'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                            const Spacer(),
                            Text(item.timeAgo,
                              style: GoogleFonts.poppins(fontSize: 11, color: textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Title ──────────────────────────────
                        Text(item.title,
                          style: GoogleFonts.poppins(
                            fontSize: 22, fontWeight: FontWeight.w800,
                            color: textPrimary, height: 1.2)),
                        const SizedBox(height: 10),

                        // ── Price row ──────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\u20B9${item.price.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 30, fontWeight: FontWeight.w900,
                                color: _kPrimary, height: 1.0),
                            ),
                            const SizedBox(width: 10),
                            if (item.status != 'available')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: item.status == 'sold'
                                      ? const Color(0xFFEC4899)
                                      : const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.status == 'sold' ? 'SOLD' : 'UNAVAILABLE',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white, fontSize: 10,
                                    fontWeight: FontWeight.w800),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Divider ────────────────────────────
                        Divider(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                        const SizedBox(height: 20),

                        // ── Description ────────────────────────
                        _SectionTitle(title: 'Description', isDark: isDark),
                        const SizedBox(height: 8),
                        Text(item.description,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5, color: textSecondary, height: 1.65)),
                        const SizedBox(height: 24),

                        // ── Specifications ─────────────────────
                        _SectionTitle(title: 'Specifications', isDark: isDark),
                        const SizedBox(height: 12),
                        _SpecTable(rows: [
                          _SpecRow('Condition', item.condition),
                          _SpecRow('Location',  item.location),
                          _SpecRow('Category',  item.category),
                        ], isDark: isDark, surface: surface),
                        const SizedBox(height: 24),

                        // ── Seller card ────────────────────────
                        _SectionTitle(title: 'Listed by', isDark: isDark),
                        const SizedBox(height: 10),
                        _SellerCard(item: item, isDark: isDark, surface: surface),
                        const SizedBox(height: 24),

                        // ── Owner actions ──────────────────────
                        if (isOwner) ...[
                          _SectionTitle(title: 'Manage Listing', isDark: isDark),
                          const SizedBox(height: 12),
                          _OwnerActions(item: item, currentUser: currentUser!, isDark: isDark),
                          const SizedBox(height: 24),
                        ],

                        // Bottom breathing room for action bar
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom action bar ──────────────────────────────────────
      bottomNavigationBar: _ActionBar(item: item, isOwner: isOwner, isDark: isDark),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color  color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
        style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool   isDark;
  const _SectionTitle({required this.title, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Text(title,
      style: GoogleFonts.poppins(
        fontSize: 15, fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF1A1A2E)));
  }
}

// ── Spec table ──────────────────────────────────────────────────────────────
class _SpecRow {
  final String label, value;
  const _SpecRow(this.label, this.value);
}

class _SpecTable extends StatelessWidget {
  final List<_SpecRow> rows;
  final bool isDark;
  final Color surface;
  const _SpecTable({required this.rows, required this.isDark, required this.surface});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.07) : _kPrimary.withOpacity(0.1)),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.value.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13, color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
                  Expanded(
                    child: Text(e.value.value,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Divider(height: 1,
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          ]);
        }).toList(),
      ),
    );
  }
}

// ── Seller card ─────────────────────────────────────────────────────────────
class _SellerCard extends StatelessWidget {
  final MarketplaceItem item;
  final bool isDark;
  final Color surface;
  const _SellerCard({required this.item, required this.isDark, required this.surface});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.07) : _kPrimary.withOpacity(0.1)),
      ),
      child: Row(children: [
        // Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _kPrimary.withOpacity(0.4), width: 2),
          ),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: _kPrimary.withOpacity(0.15),
            backgroundImage: item.sellerAvatar != null
                ? CachedNetworkImageProvider(item.sellerAvatar!) : null,
            child: item.sellerAvatar == null
                ? Text(item.sellerName.isNotEmpty ? item.sellerName[0].toUpperCase() : 'S',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700,
                      color: _kPrimary))
                : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.sellerName,
              style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.verified_rounded, size: 13, color: Color(0xFF3B82F6)),
              const SizedBox(width: 4),
              Flexible(
                child: Text('Verified Campus Seller • Number Verified',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF3B82F6))),
              ),
            ]),
          ]),
        ),
        // Location chip
        if (item.location.isNotEmpty)
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_on_rounded, size: 11, color: _kPrimary),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(item.location,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 10, color: _kPrimary,
                      fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ── Owner actions panel ──────────────────────────────────────────────────────
class _OwnerActions extends StatelessWidget {
  final MarketplaceItem item;
  final dynamic currentUser;
  final bool isDark;
  const _OwnerActions({required this.item, required this.currentUser, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Edit + Delete row
      Row(children: [
        Expanded(
          child: _OutlineBtn(
            icon: Icons.edit_rounded,
            label: 'Edit',
            color: const Color(0xFF3B82F6),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ListProductScreen(currentUser: currentUser, editItem: item))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OutlineBtn(
            icon: Icons.delete_rounded,
            label: 'Delete',
            color: Colors.redAccent,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text('Delete Listing?',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  content: Text('This action cannot be undone.',
                    style: GoogleFonts.poppins(fontSize: 13)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel', style: GoogleFonts.poppins())),
                    TextButton(onPressed: () => Navigator.pop(context, true),
                      child: Text('Delete',
                        style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w700))),
                  ],
                ),
              );
              if (confirm == true) {
                await MarketplaceService().deleteListing(item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Listing deleted')));
                  Navigator.pop(context);
                }
              }
            },
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // Status dropdown
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : _kPrimary.withOpacity(0.2)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: (item.status == 'sold' || item.status == 'not_available')
                ? item.status : 'available',
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1C1B2E) : Colors.white,
            icon: Icon(Icons.expand_more_rounded,
              color: isDark ? Colors.white54 : Colors.grey),
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : const Color(0xFF1A1A2E), fontSize: 13),
            items: const [
              DropdownMenuItem(value: 'available',     child: Text('Available')),
              DropdownMenuItem(value: 'sold',          child: Text('Mark as Sold (deletes in 24h)')),
              DropdownMenuItem(value: 'not_available', child: Text('Not Available (deletes in 24h)')),
            ],
            onChanged: (v) async {
              if (v != null) {
                await MarketplaceService().updateAvailabilityStatus(item.id, v);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    ]);
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
  const _OutlineBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(
            color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }
}

// ── Bottom action bar ────────────────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final MarketplaceItem item;
  final bool isOwner, isDark;
  const _ActionBar({required this.item, required this.isOwner, required this.isDark});

  Future<void> _call() async {
    await launchUrl(Uri(scheme: 'tel', path: item.mobileNumber));
  }

  Future<void> _whatsapp() async {
    String phone = item.mobileNumber.replaceAll(RegExp(r'\D'), '');
    if (phone.length == 10) phone = '91$phone';
    await launchUrl(
      Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent('Hi, I am interested in your listing: ${item.title}')}'),
      mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF1C1B2E) : Colors.white;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16,
        MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08))),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08),
            blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: isOwner
          ? Row(children: [
              Expanded(child: _BarBtn(
                label: 'Mark Sold',
                color: const Color(0xFF10B981),
                icon: Icons.check_circle_rounded,
                onTap: () async {
                  await MarketplaceService().updateAvailabilityStatus(item.id, 'sold');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marked as Sold (visible 24h)')));
                    Navigator.pop(context);
                  }
                },
              )),
              const SizedBox(width: 10),
              Expanded(child: _BarBtn(
                label: 'Unavailable',
                color: const Color(0xFFF59E0B),
                icon: Icons.block_rounded,
                onTap: () async {
                  await MarketplaceService().updateAvailabilityStatus(item.id, 'not_available');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marked as Unavailable (visible 24h)')));
                    Navigator.pop(context);
                  }
                },
              )),
            ])
          : Row(children: [
              Expanded(child: _BarBtn(
                label: 'Call Seller',
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                contentColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                icon: Icons.phone_rounded,
                onTap: _call,
              )),
              const SizedBox(width: 12),
              Expanded(child: _BarBtn(
                label: 'WhatsApp',
                color: _kGreen,
                icon: FontAwesomeIcons.whatsapp,
                isFa: true,
                onTap: _whatsapp,
              )),
            ]),
    );
  }
}

class _BarBtn extends StatelessWidget {
  final String    label;
  final Color     color;
  final Color?    contentColor;
  final dynamic   icon;
  final bool      isFa;
  final VoidCallback onTap;
  const _BarBtn({required this.label, required this.color, this.contentColor, required this.icon,
    this.isFa = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cColor = contentColor ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          isFa
              ? FaIcon(icon as IconData, color: cColor, size: 18)
              : Icon(icon as IconData, color: cColor, size: 18),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(
            color: cColor, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }
}

// ── Image gallery ─────────────────────────────────────────────────────────────
class _ImageGallery extends StatefulWidget {
  final List<String> images;
  const _ImageGallery({required this.images});
  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.42;
    return Stack(children: [
      SizedBox(
        height: h,
        child: PageView.builder(
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => CachedNetworkImage(
            imageUrl: widget.images[i],
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: Colors.grey.shade300,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.storefront_rounded, size: 60, color: Colors.grey)),
          ),
        ),
      ),

      // Count badge
      Positioned(
        top: MediaQuery.of(context).padding.top + 60,
        right: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20)),
          child: Text('${_current + 1}/${widget.images.length}',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 11,
              fontWeight: FontWeight.w600)),
        ),
      ),

      // Dot indicators
      if (widget.images.length > 1)
        Positioned(
          bottom: 14, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.images.asMap().entries.map((e) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _current == e.key ? 18 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _current == e.key ? _kPrimary : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
            )).toList(),
          ),
        ),
    ]);
  }
}
