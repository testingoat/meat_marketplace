import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ResendTimerWidget extends StatefulWidget {
  final VoidCallback onResend;
  final int initialCountdown;

  const ResendTimerWidget({
    Key? key,
    required this.onResend,
    this.initialCountdown = 45,
  }) : super(key: key);

  @override
  State<ResendTimerWidget> createState() => _ResendTimerWidgetState();
}

class _ResendTimerWidgetState extends State<ResendTimerWidget> {
  late int _countdown;
  Timer? _timer;
  bool _canResend = false;
  int _resendAttempts = 0;

  @override
  void initState() {
    super.initState();
    _countdown = widget.initialCountdown;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _canResend = false;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  void _handleResend() {
    if (!_canResend) return;

    setState(() {
      _resendAttempts++;
      // Progressive delay: 30s, 60s, 120s
      _countdown = _resendAttempts == 1
          ? 30
          : _resendAttempts == 2
              ? 60
              : 120;
    });

    _startTimer();
    widget.onResend();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_canResend) ...[
            Text(
              'Resend code in ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText,
                  ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatTime(_countdown),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryEmerald,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ] else ...[
            Text(
              "Didn't receive the code? ",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText,
                  ),
            ),
            GestureDetector(
              onTap: _handleResend,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Resend',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryEmerald,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
