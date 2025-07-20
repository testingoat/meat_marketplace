import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RoleCardWidget extends StatefulWidget {
  final String title;
  final String description;
  final String iconName;
  final List<String> benefits;
  final String buttonText;
  final VoidCallback onTap;
  final String imageUrl;

  const RoleCardWidget({
    super.key,
    required this.title,
    required this.description,
    required this.iconName,
    required this.benefits,
    required this.buttonText,
    required this.onTap,
    required this.imageUrl,
  });

  @override
  State<RoleCardWidget> createState() => _RoleCardWidgetState();
}

class _RoleCardWidgetState extends State<RoleCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
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

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.onTap,
            child: Container(
              width: 85.w,
              margin: EdgeInsets.symmetric(horizontal: 7.5.w, vertical: 1.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.lightTheme.colorScheme.surface,
                    AppTheme.lightTheme.colorScheme.surface
                        .withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPressed
                      ? AppTheme.primaryEmerald
                      : AppTheme.primaryEmerald.withValues(alpha: 0.3),
                  width: _isPressed ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  if (_isPressed)
                    BoxShadow(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryEmerald,
                                AppTheme.accentDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CustomIconWidget(
                            iconName: widget.iconName,
                            color: AppTheme.cardWhite,
                            size: 6.w,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: AppTheme.lightTheme.textTheme.titleLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.foregroundDark,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                widget.description,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: AppTheme.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomImageWidget(
                        imageUrl: widget.imageUrl,
                        width: double.infinity,
                        height: 15.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Benefits:',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foregroundDark,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ...widget.benefits.map((benefit) => Padding(
                          padding: EdgeInsets.only(bottom: 0.5.h),
                          child: Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'check_circle',
                                color: AppTheme.primaryEmerald,
                                size: 4.w,
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.mutedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    SizedBox(height: 2.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryEmerald,
                          foregroundColor: AppTheme.cardWhite,
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          widget.buttonText,
                          style: AppTheme.lightTheme.textTheme.labelLarge
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.cardWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
