import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class AddToCartSection extends StatefulWidget {
  final bool inStock;
  final double quantity;
  final VoidCallback onAddToCart;
  final VoidCallback onViewCart;

  const AddToCartSection({
    super.key,
    required this.inStock,
    required this.quantity,
    required this.onAddToCart,
    required this.onViewCart,
  });

  @override
  State<AddToCartSection> createState() => _AddToCartSectionState();
}

class _AddToCartSectionState extends State<AddToCartSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleAddToCart() async {
    if (!widget.inStock || _isAdding) return;

    setState(() {
      _isAdding = true;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Scale animation
    await _animationController.forward();
    await _animationController.reverse();

    // Simulate adding to cart
    await Future.delayed(const Duration(milliseconds: 500));

    widget.onAddToCart();

    setState(() {
      _isAdding = false;
    });

    // Show success message
    _showAddToCartSuccess();
  }

  void _showAddToCartSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.successGreen,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                "Added to cart successfully!",
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: "View Cart",
          textColor: AppTheme.primaryEmerald,
          onPressed: widget.onViewCart,
        ),
        backgroundColor: AppTheme.foregroundDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Amount",
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                    Text(
                      "₹${(widget.quantity * 450).toStringAsFixed(2)}",
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryEmerald,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      height: 7.h,
                      decoration: BoxDecoration(
                        gradient: widget.inStock
                            ? LinearGradient(
                                colors: [
                                  AppTheme.primaryEmerald,
                                  AppTheme.accentDark,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: widget.inStock ? null : AppTheme.borderSubtle,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: widget.inStock
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryEmerald
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.inStock ? _handleAddToCart : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: _isAdding
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CustomIconWidget(
                                        iconName: 'shopping_cart',
                                        color: widget.inStock
                                            ? Colors.white
                                            : AppTheme.mutedText,
                                        size: 20,
                                      ),
                                      SizedBox(width: 2.w),
                                      Text(
                                        widget.inStock
                                            ? "Add to Cart"
                                            : "Out of Stock",
                                        style: AppTheme
                                            .lightTheme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: widget.inStock
                                              ? Colors.white
                                              : AppTheme.mutedText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (!widget.inStock) ...[
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.errorRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info',
                      color: AppTheme.errorRed,
                      size: 20,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        "This product is currently out of stock. We'll notify you when it's available again.",
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
