import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/post.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../services/feed_service.dart';
import '../comment_sheet.dart';
import '../../models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../expandable_text.dart';
import 'multi_image_carousel.dart';

class FreelanceCard extends ConsumerWidget {
  final Post post;
  final String currentUserId;

  const FreelanceCard({super.key, required this.post, required this.currentUserId});

  void _showComments(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(
        post: post,
        currentUserId: user.id,
        currentUserName: user.name,
      ),
    );
  }

  void _launchWhatsApp(String? contact) async {
    if (contact == null || contact.isEmpty) return;
    
    // Clean the phone number (remove non-digits, but keep +)
    final phone = contact.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = "https://wa.me/$phone";
    
    try {
       final uri = Uri.parse(url);
       if (await canLaunchUrl(uri)) {
         await launchUrl(uri, mode: LaunchMode.externalApplication);
       }
    } catch (e) {
      debugPrint("WhatsApp Launch Error: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final user = userState.currentUser;
    final feedService = FeedService();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF101828), // Professional Obsidian Black
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Money Emoji Pattern Background
          Positioned(
            right: 10,
            top: 20,
            child: Opacity(
              opacity: 0.1,
              child: Column(
                children: [
                  const Text("💰", style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  const Text("🚀", style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  const Text("💸", style: TextStyle(fontSize: 40)),
                ],
              ),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gig Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                      ),
                      child: Text(
                        "GIG: ${post.tag.toUpperCase()}",
                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF10B981)),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.currency_rupee_rounded, size: 10, color: Color(0xFFFACC15)),
                          Text(
                            post.budget ?? "Negotiable",
                            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFFFACC15)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Gig Details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ExpandableText(
                  text: post.content,
                  style: GoogleFonts.outfit(
                    fontSize: 18, 
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  linkColor: const Color(0xFF10B981),
                ),
              ),
              
              if (post.images != null && post.images!.isNotEmpty)
                MultiImageCarousel(imageUrls: post.images!),
                
              const SizedBox(height: 12),
              
              // Contact Footer
              Container(
                 padding: const EdgeInsets.all(20.0),
                 decoration: BoxDecoration(
                   color: Colors.white.withOpacity(0.05),
                   borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                 ),
                 child: LayoutBuilder(
                   builder: (context, constraints) {
                     return Row(
                       children: [
                         Expanded(
                           child: Row(
                             children: [
                                CircleAvatar(
                                 radius: 12,
                                 backgroundColor: Colors.white12,
                                 backgroundImage: post.authorAvatar != null ? CachedNetworkImageProvider(post.authorAvatar!) : null,
                                 child: post.authorAvatar == null ? Text((post.authorNickname ?? post.authorName)[0], style: const TextStyle(fontSize: 10, color: Colors.white54)) : null,
                               ),
                               const SizedBox(width: 8),
                               Flexible(
                                 child: Text(
                                   post.authorNickname ?? post.authorName, 
                                   style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                   overflow: TextOverflow.ellipsis,
                                   maxLines: 1,
                                 ),
                               ),
                             ],
                           ),
                         ),
                         const SizedBox(width: 8),
                         
                         // Interaction Actions
                         if (post.authorId == currentUserId) ...[
                           GestureDetector(
                             onTap: () {
                               showDialog(
                                 context: context,
                                 builder: (context) => AlertDialog(
                                   title: const Text('Delete Post?'),
                                   content: const Text('Are you sure you want to delete this post?'),
                                   actions: [
                                     TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                     TextButton(
                                       onPressed: () {
                                         feedService.deletePost(post.id);
                                         Navigator.pop(context);
                                       },
                                       child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                     ),
                                   ],
                                 ),
                               );
                             },
                             child: Row(
                               children: [
                                 const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                 const SizedBox(width: 6),
                               ],
                             ),
                           ),
                           const SizedBox(width: 12),
                         ],
                         GestureDetector(
                           onTap: () => feedService.toggleLikePost(post.id, currentUserId, !post.likedBy.contains(currentUserId)),
                           child: Row(
                             children: [
                               Icon(post.likedBy.contains(currentUserId) ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart, size: 24, color: post.likedBy.contains(currentUserId) ? Colors.redAccent : const Color(0xFF10B981)),
                               const SizedBox(width: 6),
                               Text("${post.votes}", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                             ],
                           ),
                         ),
                         const SizedBox(width: 12),
                         GestureDetector(
                           onTap: () => user != null ? _showComments(context, user) : null,
                           child: Row(
                             children: [
                               const Icon(FontAwesomeIcons.comment, size: 20, color: AppTheme.primary),
                               const SizedBox(width: 6),
                               Text("${post.commentsCount}", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                             ],
                           ),
                         ),
                         const SizedBox(width: 8),

                         // WhatsApp Button (Only if contact looks like a number)
                         if (post.contact != null && post.contact!.isNotEmpty)
                           IconButton(
                             onPressed: () => _launchWhatsApp(post.contact),
                             icon: const Icon(FontAwesomeIcons.whatsapp, size: 20, color: Color(0xFF25D366)),
                             padding: EdgeInsets.zero,
                             constraints: const BoxConstraints(),
                           ),
                         
                         const SizedBox(width: 12),
    
                         // Direct Contact Button
                         Flexible(
                           child: ElevatedButton(
                             onPressed: () => _launchWhatsApp(post.contact),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: const Color(0xFF10B981),
                               foregroundColor: Colors.white,
                               elevation: 0,
                               padding: const EdgeInsets.symmetric(horizontal: 12),
                               minimumSize: const Size(60, 36),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                             child: Text(
                               post.contact ?? "CONTACT", 
                               style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                               overflow: TextOverflow.ellipsis,
                               maxLines: 1,
                             ),
                           ),
                         ),
                       ],
                     );
                   }
                 ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
