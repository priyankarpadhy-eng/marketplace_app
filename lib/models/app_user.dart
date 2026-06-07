class AppUser {
  final String id;
  final String name;
  final String? nickname;
  final String? profileImage;
  final String? passoutYear;
  final String? branch;
  final String role; // 'student' | 'shop' | 'admin' | 'founder' | 'restaurant'
  final String email;
  final String gender; // 'male' | 'female' | 'other'
  final String phoneNumber;
  final bool phoneVerified;

  final String? shopName;
  final String? shopAddress;
  final String? shopSellerName;
  final bool isVerified;
  final String verificationStatus; // 'none' | 'pending' | 'approved' | 'rejected'
  final List<String> shopTags; // ['rental', 'marketplace', etc.]
  final List<String> shopImages;

  bool get isAdmin => role == 'admin' || role == 'founder';
  bool get isFounder => role == 'founder';
  bool get isShop => role == 'shop' || role == 'restaurant';
  bool get isRestaurant => role == 'restaurant';
  bool get isGuest => role == 'guest';
  bool get canRent => shopTags.contains('rental') || shopTags.isEmpty;
  bool get canSell => shopTags.contains('marketplace') || shopTags.isEmpty;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.nickname,
    this.profileImage,
    this.passoutYear,
    this.branch,
    required this.role,
    required this.gender,
    required this.phoneNumber,
    required this.phoneVerified,
    this.shopName,
    this.shopAddress,
    this.shopSellerName,
    this.isVerified = false,
    this.verificationStatus = 'none',
    this.shopTags = const [],
    this.shopImages = const [],
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: (data['name'] as String?) ?? (data['displayName'] as String?) ?? (data['nickname'] as String? ?? ''),
      email: (data['email'] as String?) ?? '',
      nickname: (data['nickname'] as String?) ?? (data['displayName'] as String?),
      profileImage: (data['profile_image'] as String?) ?? (data['profileImage'] as String?) ?? (data['photoURL'] as String?),
      passoutYear: (data['passout_year'] as String?) ?? (data['passoutYear'] as String?) ?? (data['classYear'] as String?),
      branch: (data['branch'] as String?) ?? (data['major'] as String?),
      role: (data['role'] as String?) ?? 'student',
      gender: (data['gender'] as String?) ?? 'other',
      phoneNumber: (data['phone_number'] as String?) ?? (data['phoneNumber'] as String?) ?? '',
      phoneVerified: (data['phone_verified'] as bool?) ?? (data['phoneVerified'] as bool?) ?? false,
      shopName: data['shop_name'] as String?,
      shopAddress: data['shop_address'] as String?,
      shopSellerName: data['shop_seller_name'] as String?,
      isVerified: (data['is_verified'] as bool?) ?? false,
      verificationStatus: (data['verification_status'] as String?) ?? 'none',
      shopTags: List<String>.from(data['shop_tags'] ?? []),
      shopImages: List<String>.from(data['shop_images'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'nickname': nickname,
      'profile_image': profileImage,
      'passout_year': passoutYear,
      'branch': branch,
      'role': role,
      'gender': gender,
      'phone_number': phoneNumber,
      'phone_verified': phoneVerified,
      'shop_name': shopName,
      'shop_address': shopAddress,
      'shop_seller_name': shopSellerName,
      'is_verified': isVerified,
      'verification_status': verificationStatus,
      'shop_tags': shopTags,
      'shop_images': shopImages,
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? nickname,
    String? profileImage,
    String? passoutYear,
    String? branch,
    String? phoneNumber,
    String? gender,
    bool? phoneVerified,
    String? shopName,
    String? shopAddress,
    String? shopSellerName,
    bool? isVerified,
    String? verificationStatus,
    List<String>? shopTags,
    List<String>? shopImages,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      profileImage: profileImage ?? this.profileImage,
      passoutYear: passoutYear ?? this.passoutYear,
      branch: branch ?? this.branch,
      role: role,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      shopSellerName: shopSellerName ?? this.shopSellerName,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      shopTags: shopTags ?? this.shopTags,
      shopImages: shopImages ?? this.shopImages,
    );
  }
}
