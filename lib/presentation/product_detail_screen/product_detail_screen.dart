import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/add_to_cart_section.dart';
import './widgets/expandable_info_section.dart';
import './widgets/product_image_gallery.dart';
import './widgets/product_info_section.dart';
import './widgets/quantity_selector.dart';
import './widgets/reviews_section.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ScrollController _scrollController;
  bool _isAppBarVisible = false;
  double _selectedQuantity = 1.0;

  // Mock product data
  final Map<String, dynamic> _productData = {
    "id": "prod_001",
    "name": "Premium Fresh Chicken Breast",
    "description":
        """Fresh, tender chicken breast sourced from free-range farms. Perfect for grilling, roasting, or pan-frying. Our chicken is antibiotic-free and raised with the highest standards of animal welfare. Each piece is carefully selected for quality and freshness.

Rich in protein and low in fat, chicken breast is an excellent choice for healthy meals. The meat is versatile and can be used in various cuisines - from Indian curries to continental dishes.""",
    "price": 450.0,
    "originalPrice": 520.0,
    "images": [
      "https://images.pexels.com/photos/2338407/pexels-photo-2338407.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "https://images.pexels.com/photos/616354/pexels-photo-616354.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "https://images.pexels.com/photos/2338408/pexels-photo-2338408.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
    ],
    "inStock": true,
    "isWishlisted": false,
    "seller": {
      "id": "seller_001",
      "name": "Fresh Meat Co.",
      "businessName": "Fresh Meat Company Pvt Ltd",
      "rating": 4.8,
      "reviewCount": 1247,
      "gstin": "29ABCDE1234F1Z5",
      "fssaiLicense": "12345678901234",
      "address":
          "Shop No. 15, Central Market, Sector 17, Chandigarh, Punjab 160017",
      "latitude": 30.7333,
      "longitude": 76.7794,
    },
    "nutritionalInfo": {
      "protein": 31.0,
      "fat": 3.6,
      "carbs": 0.0,
      "calories": 165,
      "iron": 0.9,
      "vitaminB12": 0.3,
    },
    "reviewSummary": {
      "averageRating": 4.6,
      "totalReviews": 234,
      "ratingBreakdown": {
        5: 156,
        4: 52,
        3: 18,
        2: 5,
        1: 3,
      },
    },
  };

  final List<Map<String, dynamic>> _reviews = [
    {
      "id": "rev_001",
      "customerName": "Rajesh Kumar",
      "rating": 5,
      "comment":
          "Excellent quality chicken! Very fresh and tender. The packaging was also very good. Will definitely order again.",
      "date": DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      "id": "rev_002",
      "customerName": "Priya Sharma",
      "rating": 4,
      "comment":
          "Good quality meat, delivered on time. The chicken was fresh and the taste was great. Slightly expensive but worth it for the quality.",
      "date": DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      "id": "rev_003",
      "customerName": "Amit Singh",
      "rating": 5,
      "comment":
          "Best chicken I've bought online! The seller is very reliable and the delivery was prompt. Highly recommended for quality conscious buyers.",
      "date": DateTime.now().subtract(const Duration(days: 8)),
    },
    {
      "id": "rev_004",
      "customerName": "Neha Gupta",
      "rating": 4,
      "comment":
          "Fresh and good quality chicken. The packaging could be better but overall satisfied with the purchase. Will order again.",
      "date": DateTime.now().subtract(const Duration(days: 12)),
    },
    {
      "id": "rev_005",
      "customerName": "Vikram Patel",
      "rating": 5,
      "comment":
          "Outstanding quality! The chicken was so fresh and tender. Perfect for my restaurant needs. Great service from the seller.",
      "date": DateTime.now().subtract(const Duration(days: 15)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final bool shouldShowAppBar = _scrollController.offset > 200;
    if (shouldShowAppBar != _isAppBarVisible) {
      setState(() {
        _isAppBarVisible = shouldShowAppBar;
      });
    }
  }

  void _toggleWishlist() {
    HapticFeedback.lightImpact();
    setState(() {
      _productData["isWishlisted"] = !(_productData["isWishlisted"] as bool);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          (_productData["isWishlisted"] as bool)
              ? "Added to wishlist"
              : "Removed from wishlist",
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareProduct() {
    final String productName = _productData["name"] as String;
    final String productPrice = "₹${_productData["price"]}";
    final String shareText =
        "Check out this amazing product: $productName for $productPrice per kg. Fresh and high quality meat from trusted sellers!";

    Share.share(shareText, subject: productName);
  }

  void _showLocationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Seller Location",
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.mutedText,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppTheme.borderSubtle, height: 1),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _productData["seller"]["businessName"] as String,
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      _productData["seller"]["address"] as String,
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                    ),
                    SizedBox(height: 3.h),
                    Container(
                      height: 30.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'location_on',
                              color: AppTheme.primaryEmerald,
                              size: 48,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              "Map View",
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                color: AppTheme.mutedText,
                              ),
                            ),
                            Text(
                              "Interactive map would be displayed here",
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart() {
    // Add to cart logic would be implemented here
    print("Added $_selectedQuantity kg to cart");
  }

  void _viewCart() {
    // Navigate to cart screen
    Navigator.pushNamed(context, '/cart-screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: _isAppBarVisible
            ? AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.95)
            : Colors.transparent,
        elevation: _isAppBarVisible ? 2 : 0,
        leading: Container(
          margin: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: _isAppBarVisible
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: _isAppBarVisible ? AppTheme.foregroundDark : Colors.white,
              size: 24,
            ),
          ),
        ),
        title: _isAppBarVisible
            ? Text(
                _productData["name"] as String,
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        actions: [
          Container(
            margin: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: _isAppBarVisible
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: _shareProduct,
              icon: CustomIconWidget(
                iconName: 'share',
                color: _isAppBarVisible ? AppTheme.mutedText : Colors.white,
                size: 24,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 2.w, top: 2.w, bottom: 2.w),
            decoration: BoxDecoration(
              color: _isAppBarVisible
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: _toggleWishlist,
              icon: CustomIconWidget(
                iconName: (_productData["isWishlisted"] as bool)
                    ? 'favorite'
                    : 'favorite_border',
                color: (_productData["isWishlisted"] as bool)
                    ? Colors.red
                    : (_isAppBarVisible ? AppTheme.mutedText : Colors.white),
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  ProductImageGallery(
                    images: (_productData["images"] as List).cast<String>(),
                    productName: _productData["name"] as String,
                  ),
                  ProductInfoSection(
                    product: _productData,
                    onWishlistToggle: _toggleWishlist,
                    onShare: _shareProduct,
                  ),
                  SizedBox(height: 2.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: QuantitySelector(
                      initialQuantity: _selectedQuantity,
                      onQuantityChanged: (quantity) {
                        setState(() {
                          _selectedQuantity = quantity;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 2.h),
                  ExpandableInfoSection(
                    title: "Description",
                    content: ProductDescriptionContent(
                      description: _productData["description"] as String,
                    ),
                  ),
                  ExpandableInfoSection(
                    title: "Nutritional Information",
                    content: NutritionalInfoContent(
                      nutritionalInfo: _productData["nutritionalInfo"]
                          as Map<String, dynamic>,
                    ),
                  ),
                  ExpandableInfoSection(
                    title: "Seller Details",
                    content: SellerDetailsContent(
                      seller: _productData["seller"] as Map<String, dynamic>,
                      onLocationTap: _showLocationModal,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  ReviewsSection(
                    reviewSummary:
                        _productData["reviewSummary"] as Map<String, dynamic>,
                    reviews: _reviews,
                  ),
                  SizedBox(height: 10.h), // Space for bottom section
                ],
              ),
            ),
          ),
          AddToCartSection(
            inStock: _productData["inStock"] as bool,
            quantity: _selectedQuantity,
            onAddToCart: _addToCart,
            onViewCart: _viewCart,
          ),
        ],
      ),
    );
  }
}
