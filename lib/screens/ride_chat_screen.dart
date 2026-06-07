import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/ride.dart';
import '../services/ride_service.dart';
import '../theme/app_theme.dart';

class RideChatScreen extends StatefulWidget {
  final Ride ride;
  final AppUser currentUser;

  const RideChatScreen({
    super.key,
    required this.ride,
    required this.currentUser,
  });

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final _controller = TextEditingController();
  final _service = RideService();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _service.sendMessage(
      rideId: widget.ride.id,
      sender: widget.currentUser,
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 40,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.ride.from} → ${widget.ride.to}',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              'Ride Group Chat',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Coordination Warning Banner
          _buildWarningBanner(isDark),
          
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.watchMessages(widget.ride.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data ?? [];
                if (docs.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final isSystem = data['is_system'] == true;
                    final isMe = data['sender_id'] == widget.currentUser.id;
                    final text = (data['text'] as String?) ?? '';
                    final senderName = (data['sender_name'] as String?) ?? 'Student';
                    final sentAt = data['sent_at'] != null 
                        ? DateTime.parse(data['sent_at']) 
                        : DateTime.now();

                    if (isSystem) {
                      return _buildSystemMessage(text, isDark);
                    }

                    return _buildChatBubble(
                      text: text,
                      senderName: senderName,
                      isMe: isMe,
                      sentAt: sentAt,
                      isDark: isDark,
                    );
                  },
                );
              },
            ),
          ),

          // Modern Input Bar
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.amber.withOpacity(0.1) : Colors.amber.shade50,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.amber.withOpacity(0.2) : Colors.amber.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates, size: 16, color: isDark ? Colors.amber : Colors.amber.shade900),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Coordinate now! This chat will be deleted 24 hours after departure.",
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.amber : Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.comments,
            size: 64,
            color: isDark ? Colors.white10 : Colors.black12,
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coordinate with your ride mates',
            style: TextStyle(
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble({
    required String text,
    required String senderName,
    required bool isMe,
    required DateTime sentAt,
    required bool isDark,
  }) {
    final bubbleColor = isMe 
        ? AppTheme.primary 
        : (isDark ? const Color(0xFF1E293B) : Colors.white);
    
    final textColor = isMe ? Colors.white : (isDark ? Colors.white : Colors.black87);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                senderName,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  text,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(sentAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : (isDark ? Colors.white38 : Colors.black38),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 1,
                  style: GoogleFonts.outfit(fontSize: 15, color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _send,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

