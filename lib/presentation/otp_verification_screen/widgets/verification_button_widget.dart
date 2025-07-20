import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class VerificationButtonWidget extends StatefulWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const VerificationButtonWidget({
    Key? key,
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<VerificationButtonWidget> createState() =>
      _VerificationButtonWidgetState();
}

class _VerificationButtonWidgetState extends State<VerificationButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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
    if (widget.isEnabled && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.isEnabled && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.isEnabled && !widget.isLoading ? widget.onPressed : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                height: 6.h,
                decoration: BoxDecoration(
                  gradient: widget.isEnabled
                      ? LinearGradient(
                          colors: [
                            AppTheme.primaryEmerald,
                            AppTheme.accentDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: widget.isEnabled ? null : AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: widget.isEnabled && !widget.isLoading
                      ? [
                          BoxShadow(
                            color:
                                AppTheme.primaryEmerald.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.cardWhite,
                            ),
                          ),
                        )
                      : Text(
                          'Verify',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: widget.isEnabled
                                        ? AppTheme.cardWhite
                                        : AppTheme.mutedText,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
