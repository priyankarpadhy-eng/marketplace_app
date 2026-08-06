import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import '../models/event_item.dart';
import '../models/post_comment.dart';
import 'notification_service.dart';

class FeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static List<dynamic>? _cachedFeed;

  static List<dynamic>? get cachedFeed => _cachedFeed;

  Stream<List<dynamic>> watchFeed({String tag = 'All'}) {
    // If we have cached data and it matches the tag (or we don't care), yield it immediately
    // Note: For simplicity, we only cache the 'All' feed for now
    if (tag == 'All' && _cachedFeed != null) {
      // We don't yield here because the controller logic below handles the stream
    }
    if (tag.toLowerCase() == 'events') {
      return _db.collection('events').orderBy('createdAt', descending: true).snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => EventItem.fromFirestore(doc)).toList());
    }

    if (tag != 'All') {
      return _db.collection('posts')
          .where('tag', isEqualTo: tag.toLowerCase())
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
    }

    // Combine All (Posts + Events)
    final controller = StreamController<List<dynamic>>();
    List<Post> lastPosts = [];
    List<EventItem> lastEvents = [];

    void emitMerged() {
      final merged = [...lastPosts, ...lastEvents];
      merged.sort((a, b) {
        final DateTime timeA = (a is Post) ? a.createdAt : (a as EventItem).createdAt;
        final DateTime timeB = (b is Post) ? b.createdAt : (b as EventItem).createdAt;
        return timeB.compareTo(timeA); // Newest first
      });
      if (tag == 'All') _cachedFeed = merged;
      if (!controller.isClosed) controller.add(merged);
    }

    final postsSub = _db.collection('posts').orderBy('createdAt', descending: true).snapshots().listen((snap) {
      lastPosts = snap.docs.map((d) => Post.fromFirestore(d)).toList();
      emitMerged();
    });

    final eventsSub = _db.collection('events').orderBy('createdAt', descending: true).snapshots().listen((snap) {
      lastEvents = snap.docs.map((d) => EventItem.fromFirestore(d)).toList();
      emitMerged();
    });

    controller.onCancel = () {
      postsSub.cancel();
      eventsSub.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> createPost(Post post) async {
    final docRef = await _db.collection('posts').add(post.toMap());
    
    // Broadcast notification unless it's a music post or contains multiple images (for testing)
    if (post.tag.toLowerCase() == 'music' || (post.images != null && post.images!.length > 1)) return;

    try {
      await NotificationService.instance.broadcastNotification(
        title: 'New Post! 📢',
        body: '${post.authorName} shared a new post. Tap to view!',
        type: 'post',
        relatedId: docRef.id,
      );
    } catch (e) {
      print("Failed to send post notification: $e");
    }
  }

  Future<void> toggleLikePost(String postId, String userId, bool isLiking) async {
    final docRef = _db.collection('posts').doc(postId);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data() as Map<String, dynamic>;
      final List<dynamic> likedBy = data['likedBy'] ?? [];
      
      final bool currentlyLiked = likedBy.contains(userId);
      
      if (isLiking && !currentlyLiked) {
        transaction.update(docRef, {
          'votes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId])
        });
      } else if (!isLiking && currentlyLiked) {
        transaction.update(docRef, {
          'votes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId])
        });
      }
    });
  }

  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  Future<void> reportPost(String postId, Map<String, dynamic> reportData) async {
    await _db.collection('reports').add({
      'postId': postId,
      ...reportData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Comment System ---

  Stream<List<PostComment>> watchComments(String postId) {
    return _db.collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PostComment.fromFirestore(d)).toList());
  }

  Stream<List<PostComment>> watchReplies(String postId, String commentId) {
    return _db.collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PostComment.fromFirestore(d, isReply: true)).toList());
  }

  Future<void> addComment(String postId, PostComment comment) async {
    final batch = _db.batch();
    
    // Add comment to sub-collection
    DocumentReference commentRef = _db.collection('posts').doc(postId).collection('comments').doc();
    batch.set(commentRef, comment.toMap());

    // Increment comment counter on post
    batch.update(_db.collection('posts').doc(postId), {
      'comments': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> addReply(String postId, String commentId, PostComment reply) async {
    await _db.collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .add(reply.toMap());
  }

  Future<void> likeComment(String postId, String commentId, {String? replyId}) async {
    DocumentReference ref;
    if (replyId != null) {
      ref = _db.collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .doc(replyId);
    } else {
      ref = _db.collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);
    }
    await ref.update({'likes': FieldValue.increment(1)});
  }
}
