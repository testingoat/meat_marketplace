class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final String? businessName;
  final String? businessStatus;
  final String? profileImageUrl;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.businessName,
    this.businessStatus,
    this.profileImageUrl,
    this.address,
    this.city,
    this.state,
    this.pincode,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String?,
      role: map['role'] as String,
      businessName: map['business_name'] as String?,
      businessStatus: map['business_status'] as String?,
      profileImageUrl: map['profile_image_url'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      pincode: map['pincode'] as String?,
      isVerified: map['is_verified'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'business_name': businessName,
      'business_status': businessStatus,
      'profile_image_url': profileImageUrl,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? email,
    String? fullName,
    String? phone,
    String? role,
    String? businessName,
    String? businessStatus,
    String? profileImageUrl,
    String? address,
    String? city,
    String? state,
    String? pincode,
    bool? isVerified,
  }) {
    return UserProfile(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      businessName: businessName ?? this.businessName,
      businessStatus: businessStatus ?? this.businessStatus,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
