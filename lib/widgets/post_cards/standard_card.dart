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
import 'package:provider/provider.dart';
import '../expandable_text.dart';
import '../cached_video_player.dart';

class StandardCard extends StatelessWidget {
  final Post post;
  final String currentUserId;

  const StandardCard({super.key, required this.post, required this.currentUserId});

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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    final feedService = FeedService();
    final isLiked = post.likedBy.contains(currentUserId);
    final isOwn = post.authorId == currentUserId;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(isDark), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.border(isDark), width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 19,
                    backgroundColor: AppTheme.surfaceAlt(isDark),
                    backgroundImage: post.authorAvatar != null
                        ? CachedNetworkImageProvider(post.authorAvatar!)
                        : null,
                    child: post.authorAvatar == null
                        ? Text(
                            post.authorName[0].toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accent(isDark),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                // Name + time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorNickname ?? post.authorName,
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textPrimary(isDark),
                        ),
                      ),
                      Text(
                        DateFormat('d MMM · h:mm a').format(post.createdAt),
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(isDark)),
                      ),
                    ],
                  ),
                ),
                // Tag chip
                _buildTagChip(post.tag),
                if (isOwn) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        backgroundColor: AppTheme.surface(isDark),
                        title: Text('Delete Post?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        content: const Text('Are you sure you want to delete this post?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              FeedService().deletePost(post.id);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Content ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: ExpandableText(
              text: post.content,
              style: GoogleFonts.outfit(
                fontSize: 15,
                height: 1.45,
                fontWeight: post.isBold ? FontWeight.w700 : FontWeight.normal,
                color: AppTheme.textPrimary(isDark),
              ),
              linkColor: AppTheme.accent(isDark),
            ),
          ),

          // ── Media ────────────────────────────────────────────
          if (post.image != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: post.image!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: AppTheme.surfaceAlt(isDark),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.red)),
                  ),
                ),
              ),
            ),

          if (post.video != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedVideoPlayer(url: post.video!),
              ),
            ),

          // ── Action Bar ───────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceAlt : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border(isDark), width: 0.8),
            ),
            child: Row(
              children: [
                _buildAction(
                  icon: isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                  count: '${post.votes}',
                  color: isLiked ? Colors.red : AppTheme.textSecondary(isDark),
                  onTap: () => feedService.toggleLikePost(post.id, currentUserId, !isLiked),
                ),
                const SizedBox(width: 20),
                _buildAction(
                  icon: FontAwesomeIcons.comment,
                  count: '${post.commentsCount}',
                  color: AppTheme.textSecondary(isDark),
                  onTap: () => user != null ? _showComments(context, user) : null,
                ),
                const Spacer(),
                Icon(Icons.share_rounded, size: 18, color: AppTheme.textSecondary(isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    Color color;
    switch (tag.toLowerCase()) {
      case 'events':      color = AppTheme.profileAccent; break;
      case 'discussion':  color = AppTheme.primary;       break;
      case 'help':        color = AppTheme.rideAccent;    break;
      case 'confession':  color = Colors.purple;          break;
      case 'freelancing': color = AppTheme.success;       break;
      case 'poetic':      color = Colors.teal;            break;
      default:            color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Text(
        tag.toUpperCase(),
        style: GoogleFonts.roboto(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAction({required IconData icon, required String count, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          FaIcon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(count, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
