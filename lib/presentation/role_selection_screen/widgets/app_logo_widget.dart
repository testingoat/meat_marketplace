import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AppLogoWidget extends StatelessWidget {
  const AppLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Column(
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryEmerald,
                  AppTheme.accentDark,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'storefront',
                color: AppTheme.cardWhite,
                size: 10.w,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Meat Marketplace',
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.foregroundDark,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Fresh • Quality • Trusted',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedText,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
