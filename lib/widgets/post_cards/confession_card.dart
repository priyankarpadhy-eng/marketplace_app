import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/post.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../services/feed_service.dart';
import '../comment_sheet.dart';
import '../../models/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../expandable_text.dart';

class ConfessionCard extends ConsumerWidget {
  final Post post;
  final String currentUserId;

  const ConfessionCard({super.key, required this.post, required this.currentUserId});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final user = userState.currentUser;
    final feedService = FeedService();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F5), // Soft Pink Letter Paper
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF9A8D4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBCFE8).withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Letter Background Overlay (Subtle)
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(FontAwesomeIcons.solidEnvelopeOpen, size: 80, color: const Color(0xFFF9A8D4).withOpacity(0.1)),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Letter Header
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0, left: 20.0, right: 10.0, bottom: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "TO MY DEAREST",
                                style: GoogleFonts.outfit(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.w900, 
                                  letterSpacing: 1.2,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 40,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Letter Body
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: ExpandableText(
                            text: post.content,
                            style: GoogleFonts.outfit(
                              fontSize: 18, 
                              height: 1.6,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF991B1B).withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                            ),
                            linkColor: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (post.image != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20, right: 20),
                      child: Transform.rotate(
                        angle: 0.12,
                        child: Container(
                          width: 85,
                          height: 85,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(4, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: post.image!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Letter Footer
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "SIGNED WITH LOVE",
                            style: GoogleFonts.outfit(
                              fontSize: 10, 
                              fontWeight: FontWeight.w900, 
                              color: const Color(0xFFDC2626).withOpacity(0.5),
                            ),
                          ),
                          Text(
                            post.authorNickname ?? post.authorName,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFFDC2626)),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // The heart count section
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (post.authorId == currentUserId) ...[
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
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
                          ),
                          const SizedBox(width: 8),
                        ],
                        _buildHeartAction(
                          post.votes, 
                          isLiked: post.likedBy.contains(currentUserId),
                          onTap: () => feedService.toggleLikePost(post.id, currentUserId, !post.likedBy.contains(currentUserId))
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: GestureDetector(
                            onTap: () => user != null ? _showComments(context, user) : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(FontAwesomeIcons.comment, size: 18, color: Color(0xFFDC2626)),
                                  const SizedBox(width: 6),
                                  Text("${post.commentsCount}", style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(FontAwesomeIcons.solidPaperPlane, size: 14, color: Color(0xFFDC2626)),
                      ],
                    ),
                  ],
                ),
                              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeartAction(int count, {VoidCallback? onTap, bool isLiked = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart, size: 24, color: const Color(0xFFDC2626)),
            const SizedBox(width: 6),
            Text("${count}", style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
