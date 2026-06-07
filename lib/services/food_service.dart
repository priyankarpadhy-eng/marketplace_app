import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_models.dart';
import 'notification_service.dart';

class FoodService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Shop Methods ──────────────────────────────────────────────────

  Stream<List<FoodShop>> getShops() {
    return _db.collection('food_shops').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FoodShop.fromFirestore(doc)).toList();
    });
  }

  Future<void> updateShopStatus(String shopId, ShopStatus status) async {
    // 1. Fetch shop details for the notification
    final shopDoc = await _db.collection('food_shops').doc(shopId).get();
    final shopName = shopDoc.exists ? (shopDoc.data()?['name'] ?? 'A restaurant') : 'A restaurant';

    // 2. Update status
    await _db.collection('food_shops').doc(shopId).set({
      'status': status.toString().split('.').last,
    }, SetOptions(merge: true));

    // 3. Prepare messages
    String ownerMsg = '';
    String userMsg = '';
    
    switch (status) {
      case ShopStatus.open:
        ownerMsg = 'You have opened your shop! 🔓';
        userMsg = '$shopName has opened their shop! 🍔';
        break;
      case ShopStatus.closed:
        ownerMsg = 'You have closed your shop. 🔒';
        userMsg = '$shopName has closed their shop. 😴';
        break;
      case ShopStatus.dineInOnly:
        ownerMsg = 'You have opened only for dine-in. 🪑';
        userMsg = '$shopName is open for dine-in only (no delivery). 🍽️';
        break;
    }

    // 4. Notify Owner
    await NotificationService.instance.sendNotification(
      userId: shopId,
      title: 'Status Updated',
      body: ownerMsg,
      type: 'shop_status_update',
    );

    // Removed broadcast to all_users to prevent notification spam.
    // In a production app, only users who "favorited" the shop should be notified.
  }

  Future<void> updateShopDetails(String shopId, Map<String, dynamic> data) async {
    await _db.collection('food_shops').doc(shopId).set(data, SetOptions(merge: true));
  }

  // ── Menu Methods ──────────────────────────────────────────────────

  Stream<List<FoodCategory>> getMenu(String shopId) {
    return _db
        .collection('food_shops')
        .doc(shopId)
        .collection('menu')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FoodCategory.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addMenuCategory(String shopId, String categoryName) async {
    await _db
        .collection('food_shops')
        .doc(shopId)
        .collection('menu')
        .add({'name': categoryName, 'items': []});
  }

  Future<void> updateMenuCategory(String shopId, String categoryId, Map<String, dynamic> data) async {
    await _db
        .collection('food_shops')
        .doc(shopId)
        .collection('menu')
        .doc(categoryId)
        .update(data);
  }

  Future<void> deleteMenuCategory(String shopId, String categoryId) async {
    await _db
        .collection('food_shops')
        .doc(shopId)
        .collection('menu')
        .doc(categoryId)
        .delete();
  }

  Stream<List<Map<String, dynamic>>> getAllFoodItems() {
    return _db.collectionGroup('menu').snapshots().asyncMap((snapshot) async {
      List<Map<String, dynamic>> allItems = [];
      // Cache shop docs to avoid redundant reads
      Map<String, FoodShop> shopsMap = {};

      for (var doc in snapshot.docs) {
        final shopId = doc.reference.parent.parent!.id;
        
        if (!shopsMap.containsKey(shopId)) {
          final shopDoc = await _db.collection('food_shops').doc(shopId).get();
          if (shopDoc.exists) {
            shopsMap[shopId] = FoodShop.fromFirestore(shopDoc);
          }
        }
        
        final shop = shopsMap[shopId];
        if (shop == null) continue;

        final category = FoodCategory.fromMap(doc.id, doc.data());
        
        for (var item in category.items) {
          allItems.add({
            'item': item,
            'category': category.name,
            'shop': shop,
          });
        }
      }
      return allItems;
    });
  }

  // ── Order Methods ─────────────────────────────────────────────────

  Future<void> placeOrder(FoodOrder order) async {
    // 1. Calculate Daily Order Number
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    final todayOrders = await _db.collection('food_orders')
        .where('shopId', isEqualTo: order.shopId)
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .get();
    
    final nextNumber = todayOrders.docs.length + 1;

    // 2. Add Order with number
    final orderData = order.toMap();
    orderData['dailyOrderNumber'] = nextNumber;
    
    final docRef = await _db.collection('food_orders').add(orderData);
    
    // 3. Notify Restaurant
    final itemsList = order.items.map((i) => '${i.quantity}x ${i.name}').join(', ');
    await NotificationService.instance.sendNotification(
      userId: order.shopId,
      title: 'New Order #$nextNumber! 🍔',
      body: 'Items: $itemsList',
      type: 'food_order',
      relatedId: docRef.id,
    );

    // 4. Notify Customer
    await NotificationService.instance.sendNotification(
      userId: order.customerId,
      title: 'Order Placed! #$nextNumber 🍕',
      body: 'Total amount: ₹${order.totalAmount}',
      type: 'food_order_update',
      relatedId: docRef.id,
    );
  }

  Stream<List<FoodOrder>> getShopOrders(String shopId) {
    return _db
        .collection('food_orders')
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FoodOrder.fromFirestore(doc)).toList();
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status, String customerId) async {
    await _db.collection('food_orders').doc(orderId).update({
      'status': status.toString().split('.').last,
    });

    // Notify Customer
    String title = 'Order Update';
    String body = 'Your order status has changed to ${status.toString().split('.').last.replaceAll('_', ' ')}';
    
    if (status == OrderStatus.confirmed) {
      title = 'Order Confirmed! ✅';
      body = 'The restaurant is preparing your food.';
    } else if (status == OrderStatus.delivered) {
      title = 'Order Delivered! 🍕';
      body = 'Enjoy your meal!';
    }

    await NotificationService.instance.sendNotification(
      userId: customerId,
      title: title,
      body: body,
      type: 'food_order_update',
      relatedId: orderId,
    );
  }

  Stream<List<FoodOrder>> getUserOrders(String userId) {
    return _db.collection('food_orders')
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FoodOrder.fromFirestore(doc)).toList());
  }

  // ── Stats ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getShopStats(String shopId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    // Today's stats
    final todayQuery = await _db
        .collection('food_orders')
        .where('shopId', isEqualTo: shopId)
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .get();

    double todayRevenue = 0;
    for (var doc in todayQuery.docs) {
      if (doc.data()['status'] != 'cancelled') {
        todayRevenue += (doc.data()['totalAmount'] ?? 0.0).toDouble();
      }
    }

    // All-time stats
    final allTimeQuery = await _db
        .collection('food_orders')
        .where('shopId', isEqualTo: shopId)
        .get();

    double totalRevenue = 0;
    for (var doc in allTimeQuery.docs) {
      if (doc.data()['status'] == 'delivered') {
        totalRevenue += (doc.data()['totalAmount'] ?? 0.0).toDouble();
      }
    }

    return {
      'todayOrders': todayQuery.docs.length,
      'todayRevenue': todayRevenue,
      'totalOrders': allTimeQuery.docs.length,
      'totalRevenue': totalRevenue,
    };
  }
}
