import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../models/app_user.dart';
import 'private_chat_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loader.dart';

class ConversationsScreen extends StatefulWidget {
  final AppUser currentUser;

  const ConversationsScreen({super.key, required this.currentUser});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(isDark),
      appBar: AppBar(
        title: Text("Messages", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () {}, icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 20)),
        ],
      ),
      body: StreamBuilder<List<ChatConversation>>(
        stream: _chatService.watchConversations(widget.currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoader();
          }
          final convs = snapshot.data ?? [];
          if (convs.isEmpty) {
            return const Center(child: Text("No conversations yet. Start chatting!"));
          }

          return ListView.builder(
            itemCount: convs.length,
            itemBuilder: (context, index) {
              final conv = convs[index];
              return _ConversationItem(
                conversation: conv,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PrivateChatScreen(
                        conversationId: conv.id,
                        chatName: conv.name,
                        currentUser: widget.currentUser,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationItem extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const _ConversationItem({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border(isDark))),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primary,
              child: Text(
                conversation.name.isNotEmpty ? conversation.name[0].toUpperCase() : "?",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conversation.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(conversation.lastTime),
                        style: TextStyle(color: AppTheme.textSecondary(isDark), fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppTheme.textSecondary(isDark), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
