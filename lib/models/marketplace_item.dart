import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceItem {
  final String id;
  final String title;
  final double price;
  final String category;
  final String condition;
  final String description;
  final String location;
  final String mobileNumber;
  final List<String> images; // Maintains backward/forward compatibility
  final String image;        // Direct mapping for 'image' string in DB
  final String sellerName;
  final String sellerId;
  final String? sellerAvatar;
  final int favorites;
  final String priceUnit;
  final bool isSold;
  final String status; // 'available', 'not_available', 'sold'
  final DateTime? statusUpdatedAt;
  final DateTime createdAt;
  final bool broadcasted; // Whether the listing was broadcasted
  final DateTime? broadcastedAt;

  MarketplaceItem({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.condition,
    required this.description,
    required this.location,
    required this.mobileNumber,
    required this.images,
    required this.image,
    required this.sellerName,
    required this.sellerId,
    this.sellerAvatar,
    this.favorites = 0,
    this.priceUnit = '',
    this.isSold = false,
    this.status = 'available',
    this.statusUpdatedAt,
    required this.createdAt,
    this.broadcasted = false,
    this.broadcastedAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  factory MarketplaceItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final imageStr = data['image'] as String? ?? '';
    final imageList = List<String>.from(data['images'] ?? (imageStr.isNotEmpty ? [imageStr] : []));
    
    return MarketplaceItem(
      id: doc.id,
      title: data['title'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      category: data['category'] ?? 'Other',
      condition: data['condition'] ?? 'Good',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      image: imageStr,
      images: imageList,
      sellerName: data['seller'] ?? data['sellerName'] ?? 'Anonymous',
      sellerId: data['sellerId'] ?? '',
      sellerAvatar: data['sellerAvatar'],
      favorites: (data['favorites'] ?? 0) as int,
      priceUnit: data['priceUnit'] ?? '',
      isSold: data['isSold'] ?? (data['status'] == 'sold'),
      status: data['status'] ?? 'available',
      statusUpdatedAt: (data['statusUpdatedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          (data['created_at'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      broadcasted: data['broadcasted'] ?? false,
      broadcastedAt: (data['broadcastedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'priceUnit': priceUnit,
      'category': category,
      'condition': condition,
      'description': description,
      'location': location,
      'mobileNumber': mobileNumber,
      'image': images.isNotEmpty ? images.first : '',
      'images': images,
      'seller': sellerName,
      'sellerId': sellerId,
      'sellerAvatar': sellerAvatar,
      'favorites': favorites,
      'isSold': isSold || (status == 'sold'),
      'status': status,
      'statusUpdatedAt': statusUpdatedAt != null ? Timestamp.fromDate(statusUpdatedAt!) : null,
      'createdAt': FieldValue.serverTimestamp(),
      'broadcasted': broadcasted,
      'broadcastedAt': broadcasted ? FieldValue.serverTimestamp() : null,
    };
  }

  factory MarketplaceItem.fromMap(String id, Map<String, dynamic> data) {
    final imageStr = data['image'] as String? ?? '';
    final imageList = List<String>.from(data['images'] ?? (imageStr.isNotEmpty ? [imageStr] : []));
    
    return MarketplaceItem(
      id: id,
      title: data['title'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      category: data['category'] ?? 'Other',
      condition: data['condition'] ?? 'Good',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      mobileNumber: data['mobile_number'] ?? data['mobileNumber'] ?? '',
      image: imageStr,
      images: imageList,
      sellerName: data['seller_name'] ?? data['sellerName'] ?? data['seller'] ?? 'Anonymous',
      sellerId: data['seller_id'] ?? data['sellerId'] ?? '',
      sellerAvatar: data['sellerAvatar'],
      favorites: (data['favorites'] ?? 0) as int,
      priceUnit: data['priceUnit'] ?? '',
      isSold: data['is_sold'] ?? data['isSold'] ?? (data['status'] == 'sold'),
      status: data['status'] ?? 'available',
      statusUpdatedAt: data['statusUpdatedAt'] is Timestamp 
          ? (data['statusUpdatedAt'] as Timestamp).toDate() 
          : DateTime.tryParse(data['statusUpdatedAt']?.toString() ?? ''),
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.tryParse(data['created_at'] ?? data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      broadcasted: data['broadcasted'] ?? false,
      broadcastedAt: data['broadcastedAt'] is Timestamp
          ? (data['broadcastedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['broadcastedAt']?.toString() ?? ''),
    );
  }
}
