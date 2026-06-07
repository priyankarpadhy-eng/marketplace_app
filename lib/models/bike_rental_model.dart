import 'package:cloud_firestore/cloud_firestore.dart';

class BikeListing {
  final String id;
  final String shopId;
  final String shopName;
  final String title;
  final String description;
  final double pricePerHour;
  final List<String> images;
  final bool isAvailable;
  final bool isShopOpen;
  final Map<String, dynamic> specs; // e.g., Engine, Speed, Type
  final Map<String, double> customPrices; // e.g., {"1": 100.0, "24": 1500.0}
  final DateTime createdAt;

  BikeListing({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.title,
    required this.description,
    required this.pricePerHour,
    required this.images,
    this.isAvailable = true,
    this.isShopOpen = true,
    required this.specs,
    Map<String, double>? customPrices,
    required this.createdAt,
  }) : customPrices = customPrices ?? {};

  factory BikeListing.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse custom prices
    Map<String, double> parsedCustomPrices = {};
    if (data['customPrices'] != null) {
      (data['customPrices'] as Map).forEach((key, value) {
        parsedCustomPrices[key.toString()] = (value ?? 0.0).toDouble();
      });
    }

    return BikeListing(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      shopName: data['shopName'] ?? 'Unknown Shop',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      pricePerHour: (data['pricePerHour'] ?? 0.0).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      isShopOpen: data['isShopOpen'] ?? true,
      specs: data['specs'] ?? {},
      customPrices: parsedCustomPrices,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'shopName': shopName,
      'title': title,
      'description': description,
      'pricePerHour': pricePerHour,
      'images': images,
      'isAvailable': isAvailable,
      'isShopOpen': isShopOpen,
      'specs': specs,
      'customPrices': customPrices,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class RentalRequest {
  final String id;
  final String bikeId;
  final String bikeTitle;
  final String shopId;
  final String renterId;
  final String renterName;
  final String renterPhone;
  final int durationHours;
  final double totalAmount;
  final String status; // pending, approved, declined, completed
  final DateTime createdAt;

  RentalRequest({
    required this.id,
    required this.bikeId,
    required this.bikeTitle,
    required this.shopId,
    required this.renterId,
    required this.renterName,
    required this.renterPhone,
    required this.durationHours,
    required this.totalAmount,
    this.status = 'pending',
    required this.createdAt,
  });

  factory RentalRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RentalRequest(
      id: doc.id,
      bikeId: data['bikeId'] ?? '',
      bikeTitle: data['bikeTitle'] ?? '',
      shopId: data['shopId'] ?? '',
      renterId: data['renterId'] ?? '',
      renterName: data['renterName'] ?? 'Anonymous',
      renterPhone: data['renterPhone'] ?? '',
      durationHours: data['durationHours'] ?? 1,
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bikeId': bikeId,
      'bikeTitle': bikeTitle,
      'shopId': shopId,
      'renterId': renterId,
      'renterName': renterName,
      'renterPhone': renterPhone,
      'durationHours': durationHours,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
