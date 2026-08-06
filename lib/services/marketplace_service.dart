import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/marketplace_item.dart';
import 'notification_service.dart';

class MarketplaceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── In-memory cache ───────────────────────────────────────────────
  static List<MarketplaceItem> _cachedItems = [];
  static DateTime? _lastFetchTime;
  static const Duration _bgRefreshInterval = Duration(minutes: 30);

  // ── SharedPreferences keys ────────────────────────────────────────
  static const _spCacheKey     = 'mkt_items_v2';
  static const _spRefreshPrefix = 'mkt_refresh_';
  static const int maxDailyRefreshes = 10;

  bool get hasCache => _cachedItems.isNotEmpty;

  // ── Daily refresh tracking ────────────────────────────────────────
  static String _todayKey() {
    final n = DateTime.now();
    return '$_spRefreshPrefix${n.year}_${n.month}_${n.day}';
  }

  /// Returns how many manual refreshes remain today.
  Future<int> refreshesRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_todayKey()) ?? 0;
    return (maxDailyRefreshes - used).clamp(0, maxDailyRefreshes);
  }

  /// Tries to consume one refresh quota. Returns true if allowed.
  Future<bool> consumeRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_todayKey()) ?? 0;
    if (used >= maxDailyRefreshes) return false;
    await prefs.setInt(_todayKey(), used + 1);
    return true;
  }

  // ── Persist / Load from SharedPreferences ─────────────────────────
  Future<void> _persistToLocal(List<MarketplaceItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) {
        final m = <String, dynamic>{
          'id':           item.id,
          'title':        item.title,
          'price':        item.price,
          'priceUnit':    item.priceUnit,
          'category':     item.category,
          'condition':    item.condition,
          'description':  item.description,
          'location':     item.location,
          'mobileNumber': item.mobileNumber,
          'image':        item.image,
          'images':       item.images,
          'seller':       item.sellerName,
          'sellerId':     item.sellerId,
          'sellerAvatar': item.sellerAvatar,
          'favorites':    item.favorites,
          'timeAgo':      item.timeAgo,
          'isSold':       item.isSold,
          'status':       item.status,
          'createdAt':    item.createdAt.toIso8601String(),
          'statusUpdatedAt': item.statusUpdatedAt?.toIso8601String(),
          'broadcasted':  item.broadcasted,
          'broadcastedAt': item.broadcastedAt?.toIso8601String(),
        };
        return m;
      }).toList();
      await prefs.setString(_spCacheKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<List<MarketplaceItem>?> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_spCacheKey);
      if (raw == null || raw.isEmpty) return null;
      final list = (jsonDecode(raw) as List).map((m) {
        final map = Map<String, dynamic>.from(m as Map);
        return MarketplaceItem.fromMap(map['id'] as String, map);
      }).toList();
      return list.cast<MarketplaceItem>();
    } catch (_) {
      return null;
    }
  }

  // ── Main fetch: cache-first, Firestore fallback ───────────────────
  Future<List<MarketplaceItem>> getListings({
    String category = 'All',
    String searchQuery = '',
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();

    // 1. Memory cache hit
    if (_cachedItems.isNotEmpty && !forceRefresh) {
      if (_lastFetchTime == null ||
          now.difference(_lastFetchTime!) > _bgRefreshInterval) {
        _fetchInBackground();
      }
      return _filter(_cachedItems, category, searchQuery);
    }

    // 2. SharedPreferences cache
    if (!forceRefresh) {
      final local = await _loadFromLocal();
      if (local != null && local.isNotEmpty) {
        _cachedItems = local;
        _fetchInBackground(); // silently refresh in bg
        return _filter(_cachedItems, category, searchQuery);
      }
    }

    // 3. Firestore disk cache
    if (!forceRefresh) {
      try {
        final snap = await _db
            .collection('listings')
            .limit(100)
            .get(const GetOptions(source: Source.cache));
        if (snap.docs.isNotEmpty) {
          _cachedItems = snap.docs
              .map((d) => MarketplaceItem.fromFirestore(d))
              .toList();
          _sortByCreatedAt(_cachedItems);
          _fetchInBackground();
          await _persistToLocal(_cachedItems);
          return _filter(_cachedItems, category, searchQuery);
        }
      } catch (_) {}
    }

    // 4. Server fetch (blocking)
    await _fetchFromServer();
    return _filter(_cachedItems, category, searchQuery);
  }

  // ── Background server fetch ───────────────────────────────────────
  Future<void> _fetchFromServer() async {
    try {
      final snap = await _db
          .collection('listings')
          .limit(100)
          .get(const GetOptions(source: Source.serverAndCache));
      final now = DateTime.now();
      _cachedItems = snap.docs.map((d) {
        final item = MarketplaceItem.fromFirestore(d);
        // Auto-delete expired sold/unavailable
        if ((item.status == 'sold' || item.status == 'not_available') &&
            item.statusUpdatedAt != null &&
            now.difference(item.statusUpdatedAt!).inHours >= 24) {
          deleteListing(item.id);
          return null;
        }
        return item;
      }).whereType<MarketplaceItem>().toList();
      _sortByCreatedAt(_cachedItems);
      _lastFetchTime = DateTime.now();
      await _persistToLocal(_cachedItems);
    } catch (e) {
      print('MarketplaceService: server fetch failed: $e');
    }
  }

  void _fetchInBackground() {
    _fetchFromServer().catchError((e) {
      print('MarketplaceService: bg fetch failed: $e');
    });
  }

  // ── Filter helper ─────────────────────────────────────────────────
  List<MarketplaceItem> _filter(
      List<MarketplaceItem> items, String category, String query) {
    var out = items;
    if (category != 'All') out = out.where((i) => i.category == category).toList();
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      out = out
          .where((i) =>
              i.title.toLowerCase().contains(q) ||
              i.description.toLowerCase().contains(q))
          .toList();
    }
    return out;
  }

  // ── Real-time stream (used for post-refresh live updates) ─────────
  Stream<List<MarketplaceItem>> getListingsStream({
    String category = 'All',
    String searchQuery = '',
  }) {
    return _db
        .collection('listings')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final items = <MarketplaceItem>[];
      for (final doc in snapshot.docs) {
        final item = MarketplaceItem.fromFirestore(doc);
        if ((item.status == 'sold' || item.status == 'not_available') &&
            item.statusUpdatedAt != null &&
            now.difference(item.statusUpdatedAt!).inHours >= 24) {
          deleteListing(item.id);
          continue;
        }
        items.add(item);
      }
      _sortByCreatedAt(items);
      _cachedItems = _filter(items, 'All', '');
      _persistToLocal(_cachedItems);
      return _filter(items, category, searchQuery);
    });
  }

  void _sortByCreatedAt(List<MarketplaceItem> items) {
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ── CRUD ──────────────────────────────────────────────────────────
  Future<void> createListing(MarketplaceItem item) async {
    final docRef = await _db.collection('listings').add(item.toMap());
    _cachedItems.clear();
    try {
      await NotificationService.instance.broadcastNotification(
        title: 'New Listing: ${item.title} 🛍️',
        body:
            '${item.priceUnit}${item.price} - ${item.description.length > 50 ? item.description.substring(0, 50) + "..." : item.description}',
        type: 'listing',
        relatedId: docRef.id,
        image: item.image.isNotEmpty ? item.image : null,
      );
    } catch (e) {
      print('Broadcast notification failed: $e');
    }
  }

  Future<void> deleteListing(String id) async {
    try {
      await _db.collection('listings').doc(id).delete();
    } catch (e) {
      print('deleteListing failed: $e');
    }
    _cachedItems.removeWhere((item) => item.id == id);
  }

  Future<void> updateAvailabilityStatus(String id, String status) async {
    try {
      await _db.collection('listings').doc(id).update({
        'status': status,
        'isSold': status == 'sold',
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('updateAvailabilityStatus failed: $e');
    }
    _cachedItems.clear();
  }

  Future<void> updateListingDetails(String id, Map<String, dynamic> data) async {
    try {
      await _db.collection('listings').doc(id).update(data);
      _cachedItems.clear();
    } catch (e) {
      print('updateListingDetails failed: $e');
    }
  }
}
