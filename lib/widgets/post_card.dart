import 'package:flutter/material.dart';
import '../models/post.dart';
import 'post_cards/standard_card.dart';
import 'post_cards/poetic_card.dart';
import 'post_cards/confession_card.dart';
import 'post_cards/freelance_card.dart';

import '../models/event_item.dart';
import 'post_cards/event_card.dart';

class PostCard extends StatelessWidget {
  final dynamic item;
  final String currentUserId;

  const PostCard({super.key, required this.item, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    if (item is EventItem) {
      return EventCard(event: item);
    }
    
    final post = item as Post;
    // Factory Pattern to switch layout based on Tag
    switch (post.tag.toLowerCase()) {
      case 'poetic':
        return PoeticCard(post: post, currentUserId: currentUserId);
      case 'confession':
        return ConfessionCard(post: post, currentUserId: currentUserId);
      case 'freelancing':
        return FreelanceCard(post: post, currentUserId: currentUserId);
      default:
        return StandardCard(post: post, currentUserId: currentUserId);
    }
  }
}
