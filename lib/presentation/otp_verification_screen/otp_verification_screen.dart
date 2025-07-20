import 'dart:async';
import 'dart:io' if (dart.library.io) 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/otp_input_widget.dart';
import './widgets/phone_display_widget.dart';
import './widgets/resend_timer_widget.dart';
import './widgets/success_animation_widget.dart';
import './widgets/verification_button_widget.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({Key? key}) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<State<OtpInputWidget>> _otpInputKey =
      GlobalKey<State<OtpInputWidget>>();

  String _enteredOtp = '';
  bool _isLoading = false;
  bool _hasError = false;
  bool _showSuccessAnimation = false;
  String _errorMessage = '';

  // Mock phone number - in real app this would come from previous screen
  final String _phoneNumber = '+919876543210';

  // Mock correct OTP for demonstration
  final String _correctOtp = '123456';

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupSmsAutoDetection();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  void _setupSmsAutoDetection() {
    if (!kIsWeb && Platform.isAndroid) {
      // Android SMS auto-detection would be implemented here
      // Using SMS Retriever API in production
      _simulateAutoDetection();
    } else if (!kIsWeb && Platform.isIOS) {
      // iOS auto-detection using UITextContentTypeOneTimeCode
      // This is handled automatically by the TextField widget
    }
  }

  void _simulateAutoDetection() {
    // Simulate SMS arrival after 3 seconds for demo
    Timer(const Duration(seconds: 3), () {
      if (mounted && _enteredOtp.isEmpty) {
        _handleAutoDetectedOtp(_correctOtp);
      }
    });
  }

  void _handleAutoDetectedOtp(String otp) {
    setState(() {
      _enteredOtp = otp;
      _hasError = false;
    });

    // Auto-verify after a short delay
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _handleVerification();
      }
    });
  }

  void _onOtpChanged(String otp) {
    setState(() {
      _enteredOtp = otp;
      _hasError = false;
      _errorMessage = '';
    });
  }

  void _onOtpCompleted(String otp) {
    setState(() {
      _enteredOtp = otp;
    });

    // Auto-verify when OTP is complete
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _handleVerification();
      }
    });
  }

  Future<void> _handleVerification() async {
    if (_enteredOtp.length != 6) {
      _showError('Please enter complete 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (_enteredOtp == _correctOtp) {
        // Success
        setState(() {
          _isLoading = false;
          _showSuccessAnimation = true;
        });

        HapticFeedback.lightImpact();
      } else {
        // Invalid OTP
        _showError('Invalid verification code. Please try again.');
      }
    } catch (e) {
      _showError('Verification failed. Please check your connection.');
    }
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = message;
    });

    HapticFeedback.vibrate();

    // Clear error after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _hasError = false;
          _errorMessage = '';
        });
      }
    });
  }

  void _handleResendOtp() {
    setState(() {
      _enteredOtp = '';
      _hasError = false;
      _errorMessage = '';
    });

    // Simulate resend API call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verification code sent to $_phoneNumber'),
        backgroundColor: AppTheme.primaryEmerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    // Simulate auto-detection for resent OTP
    _simulateAutoDetection();
  }

  void _handleEditPhone() {
    Navigator.pop(context);
  }

  void _handleSuccessComplete() {
    // Navigate to next screen (address setup)
    Navigator.pushReplacementNamed(context, '/role-selection-screen');
  }

  void _handleBackNavigation() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header with back button
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _handleBackNavigation,
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: AppTheme.cardWhite,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.shadowLight,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CustomIconWidget(
                              iconName: 'arrow_back',
                              color: AppTheme.foregroundDark,
                              size: 24,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Verify Phone',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.foregroundDark,
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w), // Balance the back button
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Column(
                        children: [
                          SizedBox(height: 4.h),

                          // Verification icon
                          Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryEmerald,
                                  AppTheme.accentDark,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryEmerald
                                      .withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: CustomIconWidget(
                                iconName: 'sms',
                                color: AppTheme.cardWhite,
                                size: 32,
                              ),
                            ),
                          ),

                          SizedBox(height: 4.h),

                          // Title and description
                          Text(
                            'Enter Verification Code',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.foregroundDark,
                                ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 2.h),

                          Text(
                            'We have sent a 6-digit verification code to your phone number. Please enter it below to continue.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.mutedText,
                                  height: 1.5,
                                ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: 4.h),

                          // Phone number display
                          PhoneDisplayWidget(
                            phoneNumber: _phoneNumber,
                            onEdit: _handleEditPhone,
                          ),

                          SizedBox(height: 4.h),

                          // OTP Input
                          OtpInputWidget(
                            key: _otpInputKey,
                            onOtpChanged: _onOtpChanged,
                            onOtpCompleted: _onOtpCompleted,
                            hasError: _hasError,
                          ),

                          SizedBox(height: 2.h),

                          // Error message
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _hasError ? 6.h : 0,
                            child: _hasError
                                ? Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4.w,
                                      vertical: 1.h,
                                    ),
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 4.w),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorRed
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.errorRed
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CustomIconWidget(
                                          iconName: 'error_outline',
                                          color: AppTheme.errorRed,
                                          size: 20,
                                        ),
                                        SizedBox(width: 2.w),
                                        Expanded(
                                          child: Text(
                                            _errorMessage,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppTheme.errorRed,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          SizedBox(height: 4.h),

                          // Resend timer
                          ResendTimerWidget(
                            onResend: _handleResendOtp,
                          ),

                          SizedBox(height: 6.h),

                          // Verify button
                          VerificationButtonWidget(
                            isEnabled: _enteredOtp.length == 6,
                            isLoading: _isLoading,
                            onPressed: _handleVerification,
                          ),

                          SizedBox(height: 4.h),

                          // Alternative verification options
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 2.h,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Having trouble receiving the code?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.mutedText,
                                      ),
                                ),
                                SizedBox(height: 1.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        // Handle call verification
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Voice call verification requested'),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Call me instead',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.primaryEmerald,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Success animation overlay
          if (_showSuccessAnimation)
            SuccessAnimationWidget(
              onAnimationComplete: _handleSuccessComplete,
            ),
        ],
      ),
    );
  }
}
