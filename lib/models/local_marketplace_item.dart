import 'package:isar/isar.dart';
import 'package:market_app/models/marketplace_item.dart';

part 'local_marketplace_item.g.dart';

@collection
class LocalMarketplaceItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String firestoreId;

  late String title;
  late double price;
  late String category;
  late String condition;
  late String description;
  late String location;
  late String mobileNumber;
  late List<String> images;
  late String image;
  late String sellerName;
  late String sellerId;
  String? sellerAvatar;
  late int favorites;
  late String priceUnit;
  late String timeAgo;
  late bool isSold;
  late String status;
  DateTime? statusUpdatedAt;
  late DateTime createdAt;
  late bool broadcasted;
  DateTime? broadcastedAt;

  // Helper methods to convert to/from the main model
  MarketplaceItem toModel() {
    return MarketplaceItem(
      id: firestoreId,
      title: title,
      price: price,
      category: category,
      condition: condition,
      description: description,
      location: location,
      mobileNumber: mobileNumber,
      images: images,
      image: image,
      sellerName: sellerName,
      sellerId: sellerId,
      sellerAvatar: sellerAvatar,
      favorites: favorites,
      priceUnit: priceUnit,
      isSold: isSold,
      status: status,
      statusUpdatedAt: statusUpdatedAt,
      createdAt: createdAt,
      broadcasted: broadcasted,
      broadcastedAt: broadcastedAt,
    );
  }

  static LocalMarketplaceItem fromModel(MarketplaceItem item) {
    return LocalMarketplaceItem()
      ..firestoreId = item.id
      ..title = item.title
      ..price = item.price
      ..category = item.category
      ..condition = item.condition
      ..description = item.description
      ..location = item.location
      ..mobileNumber = item.mobileNumber
      ..images = item.images
      ..image = item.image
      ..sellerName = item.sellerName
      ..sellerId = item.sellerId
      ..sellerAvatar = item.sellerAvatar
      ..favorites = item.favorites
      ..priceUnit = item.priceUnit
      ..timeAgo = item.timeAgo
      ..isSold = item.isSold
      ..status = item.status
      ..statusUpdatedAt = item.statusUpdatedAt
      ..createdAt = item.createdAt
      ..broadcasted = item.broadcasted
      ..broadcastedAt = item.broadcastedAt;
  }
}
