import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/event_item.dart';
import '../../theme/app_theme.dart';
import '../expandable_text.dart';

class EventCard extends StatelessWidget {
  final EventItem event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: event.isPinned ? Colors.amber.withOpacity(0.5) : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
          width: event.isPinned ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image
          if (event.bannerUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                   CachedNetworkImage(
                    imageUrl: event.bannerUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.withOpacity(0.1)),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.withOpacity(0.1),
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                  if (event.isPinned)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(FontAwesomeIcons.thumbtack, size: 8, color: Colors.black),
                            SizedBox(width: 4),
                            Text("FEATURED", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 8)),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Text(
                        DateFormat.yMMMd().format(DateTime.parse(event.eventDate)),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.2)),
                        ),
                        child: Text(
                          event.category.toUpperCase(),
                          style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (event.eventTime != null)
                       Flexible(
                         child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             const FaIcon(FontAwesomeIcons.clock, size: 10, color: Colors.grey),
                             const SizedBox(width: 4),
                             Flexible(
                               child: Text(
                                 event.eventTime!, 
                                 style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                                 overflow: TextOverflow.ellipsis,
                                 maxLines: 1,
                               ),
                             ),
                           ],
                         ),
                       ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),

                if (event.caption.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ExpandableText(
                    text: event.caption,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                    linkColor: AppTheme.primary,
                  ),
                ],
                const SizedBox(height: 16),
                if (event.location != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location!,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Footer Action
          if (event.registrationLink != null && event.registrationLink!.isNotEmpty)
            InkWell(
              onTap: () => launchUrl(Uri.parse(event.registrationLink!)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: const Center(
                  child: Text(
                    "Register Now",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
