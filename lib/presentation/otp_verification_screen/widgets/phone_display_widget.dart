import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PhoneDisplayWidget extends StatelessWidget {
  final String phoneNumber;
  final VoidCallback onEdit;

  const PhoneDisplayWidget({
    Key? key,
    required this.phoneNumber,
    required this.onEdit,
  }) : super(key: key);

  String _formatPhoneNumber(String phone) {
    // Remove any existing formatting
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Format as +91 XXXXX-XXXXX
    if (cleanPhone.length >= 10) {
      final countryCode = cleanPhone.startsWith('91') ? '+91' : '+91';
      final number = cleanPhone.length > 10
          ? cleanPhone.substring(cleanPhone.length - 10)
          : cleanPhone;
      return '$countryCode ${number.substring(0, 5)}-${number.substring(5)}';
    }

    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        children: [
          Text(
            'Code sent to',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText,
                ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.borderSubtle,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'phone',
                      color: AppTheme.primaryEmerald,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      _formatPhoneNumber(phoneNumber),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.foregroundDark,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: EdgeInsets.all(1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                    ),
                  ),
                  child: CustomIconWidget(
                    iconName: 'edit',
                    color: AppTheme.primaryEmerald,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
