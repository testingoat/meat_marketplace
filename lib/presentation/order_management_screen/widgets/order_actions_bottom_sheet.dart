import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class OrderActionsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onViewDetails;
  final VoidCallback onContactCustomer;
  final VoidCallback onUpdateStatus;
  final VoidCallback onGenerateInvoice;

  const OrderActionsBottomSheet({
    super.key,
    required this.order,
    required this.onViewDetails,
    required this.onContactCustomer,
    required this.onUpdateStatus,
    required this.onGenerateInvoice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Order #${order['orderNumber'] ?? ''}',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          _buildActionItem(
            icon: 'visibility',
            title: 'View Details',
            onTap: () {
              Navigator.pop(context);
              onViewDetails();
            },
          ),
          _buildActionItem(
            icon: 'phone',
            title: 'Contact Customer',
            onTap: () {
              Navigator.pop(context);
              onContactCustomer();
            },
          ),
          _buildActionItem(
            icon: 'update',
            title: 'Update Status',
            onTap: () {
              Navigator.pop(context);
              onUpdateStatus();
            },
          ),
          _buildActionItem(
            icon: 'receipt',
            title: 'Generate Invoice',
            onTap: () {
              Navigator.pop(context);
              onGenerateInvoice();
            },
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: icon,
                color: AppTheme.primaryEmerald,
                size: 20,
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: AppTheme.mutedText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
