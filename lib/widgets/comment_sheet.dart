import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/post.dart';
import '../models/post_comment.dart';
import '../services/feed_service.dart';
import '../models/app_user.dart';
import 'package:intl/intl.dart';

class CommentSheet extends StatefulWidget {
  final Post post;
  final String currentUserId;
  final String currentUserName;

  const CommentSheet({
    super.key, 
    required this.post, 
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FeedService _feedService = FeedService();
  bool _isSending = false;

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() => _isSending = true);
    
    final comment = PostComment(
      id: '',
      authorId: widget.currentUserId,
      authorName: widget.currentUserName,
      content: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await _feedService.addComment(widget.post.id, comment);
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post comment: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Text(
                  "Comments",
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  "${widget.post.commentsCount}",
                  style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Comments List
          Expanded(
            child: StreamBuilder<List<PostComment>>(
              stream: _feedService.watchComments(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data ?? [];
                
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.forum_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text("No comments yet. Be the first!", 
                          style: GoogleFonts.outfit(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: comments.length,
                  itemBuilder: (context, index) => _buildCommentTile(comments[index]),
                );
              },
            ),
          ),
          
          // Input Area
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: "Add a comment...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _isSending 
                  ? const CircularProgressIndicator()
                  : CircleAvatar(
                      backgroundColor: const Color(0xFFFACC15),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                        onPressed: _submitComment,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(PostComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFFACC15).withOpacity(0.1),
            child: Text(comment.authorName[0].toUpperCase(), 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(DateFormat.jm().format(comment.createdAt), 
                      style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: GoogleFonts.outfit(fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _feedService.likeComment(widget.post.id, comment.id),
                      child: Row(
                        children: [
                          Icon(Icons.favorite_border_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text("${comment.likes}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text("Reply", style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
