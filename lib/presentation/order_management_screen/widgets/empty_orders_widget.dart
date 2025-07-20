import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class EmptyOrdersWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRefresh;

  const EmptyOrdersWidget({
    super.key,
    required this.message,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'shopping_bag',
                color: AppTheme.primaryEmerald,
                size: 15.w,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'No Orders Found',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
            if (onRefresh != null) ...[
              SizedBox(height: 4.h),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: CustomIconWidget(
                  iconName: 'refresh',
                  color: AppTheme.cardWhite,
                  size: 18,
                ),
                label: Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
