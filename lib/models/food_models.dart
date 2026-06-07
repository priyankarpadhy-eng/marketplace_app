import 'package:cloud_firestore/cloud_firestore.dart';

enum ShopStatus { open, closed, dineInOnly }

class FoodShop {
  final String id; // This will be the restaurant user's UID
  final String name;
  final String address;
  final String phoneNumber;
  final String imageUrl;
  final ShopStatus status;
  final String description;
  final List<String> tags;
  final double rating;
  final int totalReviews;
  final List<String> images;

  FoodShop({
    required this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.imageUrl,
    required this.status,
    this.description = '',
    this.tags = const [],
    this.rating = 0.0,
    this.totalReviews = 0,
    this.images = const [],
  });

  factory FoodShop.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodShop(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      status: ShopStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => ShopStatus.closed,
      ),
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      images: List<String>.from(data['images'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'status': status.toString().split('.').last,
      'description': description,
      'tags': tags,
      'rating': rating,
      'totalReviews': totalReviews,
      'images': images,
    };
  }
}

class FoodCategory {
  final String id;
  final String name;
  final List<FoodItem> items;

  FoodCategory({
    required this.id,
    required this.name,
    required this.items,
  });

  factory FoodCategory.fromMap(String id, Map<String, dynamic> data) {
    return FoodCategory(
      id: id,
      name: data['name'] ?? '',
      items: (data['items'] as List? ?? [])
          .map((item) => FoodItem.fromMap(item))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'items': items.map((i) => i.toMap()).toList(),
    };
  }
}

class FoodItem {
  final String name;
  final double price;
  final bool isAvailable;
  final String? description;
  final String? imageUrl;

  FoodItem({
    required this.name,
    required this.price,
    required this.isAvailable,
    this.description,
    this.imageUrl,
  });

  factory FoodItem.fromMap(Map<String, dynamic> data) {
    return FoodItem(
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      description: data['description'],
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'isAvailable': isAvailable,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}

enum OrderStatus { new_order, confirmed, delivered, cancelled }

class FoodOrder {
  final String id;
  final String shopId;
  final String shopName;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;

  final int? dailyOrderNumber;

  FoodOrder({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.dailyOrderNumber,
  });

  factory FoodOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodOrder(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      shopName: data['shopName'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerAddress: data['customerAddress'] ?? '',
      items: (data['items'] as List? ?? [])
          .map((item) => OrderItem.fromMap(item))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => OrderStatus.new_order,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      dailyOrderNumber: data['dailyOrderNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'shopName': shopName,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'createdAt': FieldValue.serverTimestamp(),
      'dailyOrderNumber': dailyOrderNumber,
    };
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 1,
      price: (data['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}
