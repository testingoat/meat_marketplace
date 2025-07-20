import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class ProductInfoSection extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onWishlistToggle;
  final VoidCallback onShare;

  const ProductInfoSection({
    super.key,
    required this.product,
    required this.onWishlistToggle,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product["seller"]["name"] as String,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'star',
                          color: Colors.amber,
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          "${product["seller"]["rating"]}",
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          "(${product["seller"]["reviewCount"]} reviews)",
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onShare,
                    icon: CustomIconWidget(
                      iconName: 'share',
                      color: AppTheme.mutedText,
                      size: 24,
                    ),
                  ),
                  IconButton(
                    onPressed: onWishlistToggle,
                    icon: CustomIconWidget(
                      iconName: (product["isWishlisted"] as bool)
                          ? 'favorite'
                          : 'favorite_border',
                      color: (product["isWishlisted"] as bool)
                          ? Colors.red
                          : AppTheme.mutedText,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            product["name"] as String,
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Text(
                "₹${product["price"]}",
                style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryEmerald,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                "per kg",
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText,
                ),
              ),
              if (product["originalPrice"] != null) ...[
                SizedBox(width: 3.w),
                Text(
                  "₹${product["originalPrice"]}",
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: (product["inStock"] as bool)
                  ? AppTheme.successGreen.withValues(alpha: 0.1)
                  : AppTheme.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName:
                      (product["inStock"] as bool) ? 'check_circle' : 'cancel',
                  color: (product["inStock"] as bool)
                      ? AppTheme.successGreen
                      : AppTheme.errorRed,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Text(
                  (product["inStock"] as bool) ? "In Stock" : "Out of Stock",
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: (product["inStock"] as bool)
                        ? AppTheme.successGreen
                        : AppTheme.errorRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
