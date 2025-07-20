import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BusinessHealthWidget extends StatelessWidget {
  final Map<String, dynamic> businessData;

  const BusinessHealthWidget({
    super.key,
    required this.businessData,
  });

  @override
  Widget build(BuildContext context) {
    final String approvalStatus =
        businessData['approvalStatus'] as String? ?? 'pending';
    final bool documentVerified =
        businessData['documentVerified'] as bool? ?? false;
    final int completenessPercentage =
        businessData['completenessPercentage'] as int? ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'health_and_safety',
                color: AppTheme.primaryEmerald,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Business Health',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.foregroundDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          _buildHealthItem(
            'Approval Status',
            approvalStatus,
            approvalStatus == 'approved'
                ? AppTheme.successGreen
                : approvalStatus == 'pending'
                    ? AppTheme.primaryEmerald
                    : AppTheme.errorRed,
          ),
          SizedBox(height: 2.h),
          _buildHealthItem(
            'Document Verification',
            documentVerified ? 'Verified' : 'Pending',
            documentVerified ? AppTheme.successGreen : AppTheme.errorRed,
          ),
          SizedBox(height: 2.h),
          _buildCompleteness(completenessPercentage),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String title, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.mutedText,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor,
              width: 1,
            ),
          ),
          child: Text(
            status.toUpperCase(),
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteness(int percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Account Completeness',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
            Text(
              '$percentage%',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryEmerald,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.accentLight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
