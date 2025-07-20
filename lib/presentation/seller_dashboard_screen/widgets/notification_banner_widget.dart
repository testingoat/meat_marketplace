import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationBannerWidget extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;

  const NotificationBannerWidget({
    super.key,
    required this.notifications,
  });

  @override
  State<NotificationBannerWidget> createState() =>
      _NotificationBannerWidgetState();
}

class _NotificationBannerWidgetState extends State<NotificationBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.notifications.isNotEmpty) {
      _animationController.forward();
      _startAutoSlide();
    }
  }

  void _startAutoSlide() {
    if (widget.notifications.length > 1) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          _nextNotification();
        }
      });
    }
  }

  void _nextNotification() {
    if (widget.notifications.isNotEmpty) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.notifications.length;
      });
      _animationController.reset();
      _animationController.forward();
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    final notification = widget.notifications[_currentIndex];
    final String message = notification['message'] as String? ?? '';
    final String type = notification['type'] as String? ?? 'info';

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: _getNotificationColor(type).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getNotificationColor(type),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: _getNotificationIcon(type),
              color: _getNotificationColor(type),
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                message,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: _getNotificationColor(type),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.notifications.length > 1)
              Row(
                children: List.generate(
                  widget.notifications.length,
                  (index) => Container(
                    margin: EdgeInsets.only(left: 1.w),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index == _currentIndex
                          ? _getNotificationColor(type)
                          : _getNotificationColor(type).withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return AppTheme.successGreen;
      case 'warning':
        return AppTheme.primaryEmerald;
      case 'error':
        return AppTheme.errorRed;
      default:
        return AppTheme.primaryEmerald;
    }
  }

  String _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return 'check_circle';
      case 'warning':
        return 'warning';
      case 'error':
        return 'error';
      default:
        return 'info';
    }
  }
}
