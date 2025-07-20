import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../auth_screens/login_screen.dart';
import './widgets/app_logo_widget.dart';
import './widgets/guest_browse_widget.dart';
import './widgets/role_card_widget.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      if (_authService.isAuthenticated) {
        final userProfile = await _authService.getCurrentUserProfile();
        if (userProfile != null) {
          // Navigate based on user role
          if (userProfile.role == 'seller') {
            Navigator.pushReplacementNamed(context, '/seller-dashboard-screen');
          } else if (userProfile.role == 'buyer') {
            // Navigate to buyer home screen when implemented
            Navigator.pushReplacementNamed(
                context, '/seller-dashboard-screen'); // Temporary
          } else {
            // Admin or other roles
            Navigator.pushReplacementNamed(
                context, '/seller-dashboard-screen'); // Temporary
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _handleRoleSelection(String role) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => LoginScreen(userRole: role)));
  }

  void _handleGuestBrowse() {
    // Navigate to browse products without authentication
    Navigator.pushNamed(context, '/product-detail-screen');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: Center(
              child:
                  CircularProgressIndicator(color: AppTheme.primaryEmerald)));
    }

    return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: SafeArea(
            child: SingleChildScrollView(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Column(children: [
                      SizedBox(height: 8.h),

                      // App Logo
                      AppLogoWidget(),

                      SizedBox(height: 6.h),

                      // Welcome Text
                      Text('Welcome to Meat Marketplace',
                          style: AppTheme.lightTheme.textTheme.headlineLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.foregroundDark),
                          textAlign: TextAlign.center),

                      SizedBox(height: 2.h),

                      Text(
                          'Choose your role to get started with fresh, quality meat products',
                          style: AppTheme.lightTheme.textTheme.bodyLarge
                              ?.copyWith(
                                  color: AppTheme.mutedText, height: 1.5),
                          textAlign: TextAlign.center),

                      SizedBox(height: 6.h),

                      // Role Selection Cards
                      RoleCardWidget(
                          title: 'I am a Seller',
                          iconName: 'store',
                          description:
                              'Sell your quality meat products to customers',
                          benefits: [
                            'Reach more customers',
                            'Easy inventory management',
                            'Secure payments'
                          ],
                          buttonText: 'Start Selling',
                          imageUrl: 'assets/images/no-image.jpg',
                          onTap: () => _handleRoleSelection('seller')),

                      SizedBox(height: 3.h),

                      RoleCardWidget(
                          title: 'I am a Buyer',
                          iconName: 'shopping_cart',
                          description: 'Browse and buy fresh meat products',
                          benefits: [
                            'Fresh quality meat',
                            'Convenient delivery',
                            'Best prices'
                          ],
                          buttonText: 'Start Shopping',
                          imageUrl: 'assets/images/no-image.jpg',
                          onTap: () => _handleRoleSelection('buyer')),

                      SizedBox(height: 4.h),

                      // Guest Browse Option
                      GuestBrowseWidget(onTap: _handleGuestBrowse),

                      SizedBox(height: 4.h),
                    ])))));
  }
}
