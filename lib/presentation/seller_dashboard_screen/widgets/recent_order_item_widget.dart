import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RecentOrderItemWidget extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback onTap;

  const RecentOrderItemWidget({
    super.key,
    required this.orderData,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.errorRed;
      case 'confirmed':
        return AppTheme.successGreen;
      case 'processing':
        return AppTheme.primaryEmerald;
      case 'shipped':
        return AppTheme.accentDark;
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
    final String orderNumber = orderData['orderNumber'] as String? ?? '';
    final String customerName = orderData['customerName'] as String? ?? '';
    final String amount = orderData['amount'] as String? ?? '';
    final String status = orderData['status'] as String? ?? '';
    final DateTime? orderDate = orderData['orderDate'] as DateTime?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderSubtle,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #$orderNumber',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.foregroundDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'person',
                  color: AppTheme.mutedText,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    customerName,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mutedText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'currency_rupee',
                      color: AppTheme.primaryEmerald,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      amount,
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryEmerald,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (orderDate != null)
                  Text(
                    '${orderDate.day}/${orderDate.month}/${orderDate.year}',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
