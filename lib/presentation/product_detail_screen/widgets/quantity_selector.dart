import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class QuantitySelector extends StatefulWidget {
  final double initialQuantity;
  final double minQuantity;
  final double maxQuantity;
  final double step;
  final ValueChanged<double> onQuantityChanged;

  const QuantitySelector({
    super.key,
    this.initialQuantity = 1.0,
    this.minQuantity = 0.5,
    this.maxQuantity = 10.0,
    this.step = 0.5,
    required this.onQuantityChanged,
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late double _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  void _decreaseQuantity() {
    if (_quantity > widget.minQuantity) {
      setState(() {
        _quantity = (_quantity - widget.step)
            .clamp(widget.minQuantity, widget.maxQuantity);
      });
      widget.onQuantityChanged(_quantity);
    }
  }

  void _increaseQuantity() {
    if (_quantity < widget.maxQuantity) {
      setState(() {
        _quantity = (_quantity + widget.step)
            .clamp(widget.minQuantity, widget.maxQuantity);
      });
      widget.onQuantityChanged(_quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border.all(color: AppTheme.borderSubtle),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quantity",
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildQuantityButton(
                icon: 'remove',
                onPressed:
                    _quantity > widget.minQuantity ? _decreaseQuantity : null,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${_quantity.toStringAsFixed(_quantity == _quantity.roundToDouble() ? 0 : 1)} kg",
                    textAlign: TextAlign.center,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              _buildQuantityButton(
                icon: 'add',
                onPressed:
                    _quantity < widget.maxQuantity ? _increaseQuantity : null,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            "Total: ₹${(_quantity * 450).toStringAsFixed(2)}",
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryEmerald,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required String icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 12.w,
      height: 6.h,
      decoration: BoxDecoration(
        color:
            onPressed != null ? AppTheme.primaryEmerald : AppTheme.borderSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: CustomIconWidget(
              iconName: icon,
              color: onPressed != null ? Colors.white : AppTheme.mutedText,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
