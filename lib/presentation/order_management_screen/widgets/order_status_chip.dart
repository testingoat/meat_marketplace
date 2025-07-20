import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class OrderStatusChip extends StatelessWidget {
  final String status;
  final bool isSelected;
  final VoidCallback onTap;

  const OrderStatusChip({
    super.key,
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return AppTheme.primaryEmerald;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return AppTheme.successGreen;
      case 'cancelled':
        return AppTheme.errorRed;
      default:
        return AppTheme.mutedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected
              ? _getStatusColor()
              : AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _getStatusColor() : AppTheme.borderSubtle,
            width: 1,
          ),
        ),
        child: Text(
          status,
          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
            color: isSelected ? AppTheme.cardWhite : _getStatusColor(),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
