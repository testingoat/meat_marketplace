import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/order.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import './widgets/business_health_widget.dart';
import './widgets/kpi_card_widget.dart';
import './widgets/notification_banner_widget.dart';
import './widgets/quick_action_widget.dart';
import './widgets/recent_order_item_widget.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  int _currentBottomNavIndex = 0;
  bool _isLoading = true;

  // Supabase services
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();

  // User and dashboard data
  UserProfile? _userProfile;
  List<Map<String, dynamic>> kpiData = [];
  List<Order> recentOrders = [];
  Map<String, dynamic> businessHealthData = {};
  List<Map<String, dynamic>> notifications = [];

  final List<Map<String, dynamic>> quickActions = [
    {
      "title": "Add Product",
      "iconName": "add_box",
      "route": "/add-product-screen",
    },
    {
      "title": "Manage Inventory",
      "iconName": "inventory",
      "route": "/inventory-screen",
    },
    {
      "title": "View Orders",
      "iconName": "receipt_long",
      "route": "/order-management-screen",
    },
    {
      "title": "Analytics",
      "iconName": "analytics",
      "route": "/analytics-screen",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load user profile
      _userProfile = await _authService.getCurrentUserProfile();

      if (_userProfile == null) {
        Navigator.pushReplacementNamed(context, '/role-selection-screen');
        return;
      }

      // Load dashboard data in parallel
      await Future.wait([
        _loadKPIData(),
        _loadRecentOrders(),
        _loadBusinessHealth(),
        _loadNotifications(),
      ]);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      // Show error snackbar but don't crash
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load dashboard data. Please try again.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadKPIData() async {
    try {
      final orderStats =
          await _orderService.getSellerOrderStats(_userProfile!.id);
      final productStats =
          await _productService.getSellerProductStats(_userProfile!.id);

      setState(() {
        kpiData = [
          {
            "title": "Today's Orders",
            "value": "${orderStats['todays_orders']}",
            "subtitle": "Orders",
            "trendPercentage": "+15%",
            "isPositiveTrend": true,
            "showBadge": false,
          },
          {
            "title": "Revenue",
            "value":
                "₹${(orderStats['monthly_revenue'] as double).toStringAsFixed(0)}",
            "subtitle": "This Month",
            "trendPercentage": "+8.2%",
            "isPositiveTrend": true,
            "showBadge": false,
          },
          {
            "title": "Active Products",
            "value": "${productStats['active_products']}",
            "subtitle": "Products",
            "trendPercentage": null,
            "isPositiveTrend": true,
            "showBadge": false,
          },
          {
            "title": "Pending Orders",
            "value": "${orderStats['pending_orders']}",
            "subtitle": "Need Attention",
            "trendPercentage": null,
            "isPositiveTrend": false,
            "showBadge": true,
            "badgeCount": orderStats['pending_orders'] as int,
          },
        ];
      });
    } catch (e) {
      debugPrint('Error loading KPI data: $e');
    }
  }

  Future<void> _loadRecentOrders() async {
    try {
      final orders = await _orderService.getRecentOrders(
        sellerId: _userProfile!.id,
        limit: 5,
      );

      setState(() {
        recentOrders = orders;
      });
    } catch (e) {
      debugPrint('Error loading recent orders: $e');
    }
  }

  Future<void> _loadBusinessHealth() async {
    try {
      // For now, use static data - this could be enhanced with real business metrics
      setState(() {
        businessHealthData = {
          "approvalStatus": "approved",
          "documentVerified": true,
          "completenessPercentage": 85,
        };
      });
    } catch (e) {
      debugPrint('Error loading business health: $e');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      // Create notifications based on real data
      final pendingOrdersCount = kpiData.isNotEmpty
          ? int.tryParse(kpiData[3]['value'] as String? ?? '0') ?? 0
          : 0;

      setState(() {
        notifications = [
          if (recentOrders.isNotEmpty)
            {
              "message":
                  "New order received from customer - ₹${recentOrders.first.totalAmount.toStringAsFixed(0)}",
              "type": "success",
              "timestamp": recentOrders.first.createdAt,
            },
          if (pendingOrdersCount > 0)
            {
              "message":
                  "You have $pendingOrdersCount pending orders that need attention",
              "type": "warning",
              "timestamp": DateTime.now().subtract(const Duration(minutes: 15)),
            },
          {
            "message": "Payment received for a recent order",
            "type": "success",
            "timestamp": DateTime.now().subtract(const Duration(minutes: 30)),
          },
        ];
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryEmerald,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          color: AppTheme.primaryEmerald,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildNotificationBanner(),
                _buildKPISection(),
                _buildQuickActionsSection(),
                _buildRecentOrdersSection(),
                _buildBusinessHealthSection(),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning,',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      _userProfile?.fullName ?? 'Seller',
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foregroundDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.successGreen,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      _userProfile?.businessStatus ?? 'Active',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            _userProfile?.businessName ?? 'Your Business',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryEmerald,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBanner() {
    return NotificationBannerWidget(notifications: notifications);
  }

  Widget _buildKPISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Overview',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.foregroundDark,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 20.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: kpiData.length,
            itemBuilder: (context, index) {
              final kpi = kpiData[index];
              return KpiCardWidget(
                title: kpi['title'] as String,
                value: kpi['value'] as String,
                subtitle: kpi['subtitle'] as String?,
                trendPercentage: kpi['trendPercentage'] as String?,
                isPositiveTrend: kpi['isPositiveTrend'] as bool? ?? true,
                showBadge: kpi['showBadge'] as bool? ?? false,
                badgeCount: kpi['badgeCount'] as int?,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 3.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Quick Actions',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.foregroundDark,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 3.w,
              mainAxisSpacing: 2.h,
              childAspectRatio: 1.2,
            ),
            itemCount: quickActions.length,
            itemBuilder: (context, index) {
              final action = quickActions[index];
              return QuickActionWidget(
                title: action['title'] as String,
                iconName: action['iconName'] as String,
                onTap: () => _handleQuickAction(action['route'] as String),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 3.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Orders',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.foregroundDark,
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/order-management-screen'),
                child: Text(
                  'View All',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryEmerald,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: recentOrders.isEmpty
              ? Container(
                  padding: EdgeInsets.all(4.w),
                  child: Text(
                    'No recent orders found',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mutedText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentOrders.length > 5 ? 5 : recentOrders.length,
                  itemBuilder: (context, index) {
                    final order = recentOrders[index];
                    // Convert Order to Map for widget compatibility
                    final orderData = {
                      'orderNumber': order.orderNumber,
                      'customerName':
                          'Customer', // Could be enhanced with buyer profile lookup
                      'amount': '₹${order.totalAmount.toStringAsFixed(0)}',
                      'status': order.status.toUpperCase(),
                      'orderDate': order.createdAt,
                    };
                    return RecentOrderItemWidget(
                      orderData: orderData,
                      onTap: () => _handleOrderTap(orderData),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBusinessHealthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 3.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Business Health',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.foregroundDark,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: BusinessHealthWidget(businessData: businessHealthData),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentBottomNavIndex,
      onTap: _onBottomNavTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.cardWhite,
      selectedItemColor: AppTheme.primaryEmerald,
      unselectedItemColor: AppTheme.mutedText,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'dashboard',
            color: _currentBottomNavIndex == 0
                ? AppTheme.primaryEmerald
                : AppTheme.mutedText,
            size: 24,
          ),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'inventory_2',
            color: _currentBottomNavIndex == 1
                ? AppTheme.primaryEmerald
                : AppTheme.mutedText,
            size: 24,
          ),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'receipt_long',
            color: _currentBottomNavIndex == 2
                ? AppTheme.primaryEmerald
                : AppTheme.mutedText,
            size: 24,
          ),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'analytics',
            color: _currentBottomNavIndex == 3
                ? AppTheme.primaryEmerald
                : AppTheme.mutedText,
            size: 24,
          ),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person',
            color: _currentBottomNavIndex == 4
                ? AppTheme.primaryEmerald
                : AppTheme.mutedText,
            size: 24,
          ),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, '/add-product-screen'),
      backgroundColor: AppTheme.primaryEmerald,
      child: CustomIconWidget(
        iconName: 'add',
        color: AppTheme.cardWhite,
        size: 28,
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });

    // Navigate to respective screens based on index
    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        Navigator.pushNamed(context, '/add-product-screen');
        break;
      case 2:
        Navigator.pushNamed(context, '/order-management-screen');
        break;
      case 3:
        Navigator.pushNamed(context, '/analytics-screen');
        break;
      case 4:
        _showProfileOptions();
        break;
    }
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(iconName: 'person', size: 24),
              title: Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile screen
              },
            ),
            ListTile(
              leading: CustomIconWidget(iconName: 'settings', size: 24),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings screen
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                  iconName: 'logout', size: 24, color: AppTheme.errorRed),
              title: Text(
                'Sign Out',
                style: TextStyle(color: AppTheme.errorRed),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _authService.signOut();
                Navigator.pushReplacementNamed(
                    context, '/role-selection-screen');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickAction(String route) {
    Navigator.pushNamed(context, route);
  }

  void _handleOrderTap(Map<String, dynamic> orderData) {
    final String orderNumber = orderData['orderNumber'] as String? ?? '';
    Navigator.pushNamed(
      context,
      '/order-detail-screen',
      arguments: {'orderNumber': orderNumber},
    );
  }
}
