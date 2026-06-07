import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/post.dart';
import '../../providers/user_provider.dart';
import '../../services/feed_service.dart';
import '../comment_sheet.dart';
import '../../models/app_user.dart';
import 'package:provider/provider.dart';
import '../expandable_text.dart';

class PoeticCard extends StatefulWidget {
  final Post post;
  final String currentUserId;

  const PoeticCard({super.key, required this.post, required this.currentUserId});

  @override
  State<PoeticCard> createState() => _PoeticCardState();
}

class _PoeticCardState extends State<PoeticCard> with SingleTickerProviderStateMixin {
  double _x = 0, _y = 0;
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onInteraction(Offset localPosition, Size size) {
    // Calculate relative offset from center (-10 to 10 pixels range)
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    setState(() {
      _x = ((localPosition.dx - centerX) / centerX * 15).clamp(-15.0, 15.0);
      _y = ((localPosition.dy - centerY) / centerY * 15).clamp(-15.0, 15.0);
    });
    _controller.stop();
  }

  void _resetInteraction() {
    _animation = Tween<Offset>(
      begin: Offset(_x, _y),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    
    _controller.forward(from: 0);
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _x = _animation.value.dx;
          _y = _animation.value.dy;
        });
      }
    });
  }

  void _showComments(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(
        post: widget.post,
        currentUserId: user.id,
        currentUserName: user.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (details) => _onInteraction(details.localPosition, const Size(400, 300)),
          onPanEnd: (_) => _resetInteraction(),
          onTapDown: (details) => _onInteraction(details.localPosition, const Size(400, 300)),
          onTapUp: (_) => _resetInteraction(),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  // Background Parallax Image
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(_x, _y),
                      child: Transform.scale(
                        scale: 1.2,
                        child: CachedNetworkImage(
                          imageUrl: widget.post.image ?? 'https://images.unsplash.com/photo-1518173946687-a4c8a9ba336f?q=80&w=1000&auto=format&fit=crop',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.teal.shade900),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.teal.shade900,
                            child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  if (widget.post.authorId == widget.currentUserId)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
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
                                    FeedService().deletePost(widget.post.id);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // Content Layer
                  Container(
                    constraints: const BoxConstraints(minHeight: 250),
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: constraints.maxWidth * 0.85,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ColorFilter.mode(
                              Colors.white.withOpacity(0.0),
                              BlendMode.overlay,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(FontAwesomeIcons.featherPointed, size: 24, color: Colors.white70),
                                  const SizedBox(height: 16),
                                  ExpandableText(
                                    text: widget.post.content,
                                    style: GoogleFonts.outfit(
                                      fontSize: 18, 
                                      fontWeight: FontWeight.bold, 
                                      color: Colors.white,
                                      fontStyle: FontStyle.italic,
                                      height: 1.4,
                                    ),
                                    linkColor: Colors.white70,
                                    maxLines: 4,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "— ${widget.post.authorNickname ?? widget.post.authorName}",
                                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Interaction Stats
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStat(
                          widget.post.likedBy.contains(widget.currentUserId) ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart, 
                          "${widget.post.votes}",
                          isLiked: widget.post.likedBy.contains(widget.currentUserId),
                          onTap: () => FeedService().toggleLikePost(widget.post.id, widget.currentUserId, !widget.post.likedBy.contains(widget.currentUserId)),
                        ),
                        const SizedBox(width: 24),
                        _buildStat(
                          FontAwesomeIcons.comment, 
                          "${widget.post.commentsCount}",
                          onTap: () {
                            final user = Provider.of<UserProvider>(context, listen: false).currentUser;
                            if (user != null) _showComments(context, user);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(IconData icon, String value, {VoidCallback? onTap, bool isLiked = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          FaIcon(icon, size: 24, color: isLiked ? Colors.redAccent : Colors.white70),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
