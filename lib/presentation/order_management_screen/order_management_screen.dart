import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/order.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import './widgets/empty_orders_widget.dart';
import './widgets/order_actions_bottom_sheet.dart';
import './widgets/order_card.dart';
import './widgets/order_search_bar.dart';
import './widgets/order_status_chip.dart';
import './widgets/status_update_dialog.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String selectedStatus = 'All';
  String searchQuery = '';
  bool isLoading = true;
  bool hasActiveFilters = false;

  // Supabase services
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();

  // Orders data
  List<Order> allOrders = [];
  UserProfile? _userProfile;

  final List<String> statusFilters = [
    'All',
    'Pending',
    'Confirmed',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  List<Order> get filteredOrders {
    List<Order> filtered = allOrders;

    // Filter by status
    if (selectedStatus != 'All') {
      filtered = filtered
          .where((order) =>
              order.status.toLowerCase() == selectedStatus.toLowerCase())
          .toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        final orderNumber = order.orderNumber.toLowerCase();
        final customerPhone = order.customerPhone?.toLowerCase() ?? '';
        final query = searchQuery.toLowerCase();
        return orderNumber.contains(query) || customerPhone.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadOrdersData();
    _updateFilterStatus();
  }

  Future<void> _loadOrdersData() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Get current user profile
      _userProfile = await _authService.getCurrentUserProfile();

      if (_userProfile == null) {
        Navigator.pushReplacementNamed(context, '/role-selection-screen');
        return;
      }

      // Load orders based on user role
      if (_userProfile!.role == 'seller') {
        allOrders = await _orderService.getSellerOrders();
      } else {
        allOrders = await _orderService.getBuyerOrders();
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load orders. Please try again.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _updateFilterStatus() {
    setState(() {
      hasActiveFilters = selectedStatus != 'All' || searchQuery.isNotEmpty;
    });
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      selectedStatus = status;
    });
    _updateFilterStatus();
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
    _updateFilterStatus();
  }

  Future<void> _refreshOrders() async {
    await _loadOrdersData();
    Fluttertoast.showToast(
      msg: "Orders refreshed successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _contactCustomer(Order order) {
    final phone = order.customerPhone ?? '';
    Fluttertoast.showToast(
      msg: "Calling $phone",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _showOrderActions(Order order) {
    // Convert Order to Map for widget compatibility
    final orderData = {
      'id': order.id,
      'orderNumber': order.orderNumber,
      'customerName': 'Customer', // Could be enhanced with buyer profile lookup
      'customerPhone': order.customerPhone,
      'totalAmount': '₹${order.totalAmount.toStringAsFixed(0)}',
      'status': order.status,
      'items': order.items
          .map((item) => {
                'name': item.product?.name ?? 'Product',
                'quantity': '${item.quantity} ${item.product?.unit ?? 'pcs'}',
                'price': '₹${item.totalPrice.toStringAsFixed(0)}',
              })
          .toList(),
      'address': order.deliveryAddress,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderActionsBottomSheet(
        order: orderData,
        onViewDetails: () => _viewOrderDetails(order),
        onContactCustomer: () => _contactCustomer(order),
        onUpdateStatus: () => _showStatusUpdateDialog(order),
        onGenerateInvoice: () => _generateInvoice(order),
      ),
    );
  }

  void _viewOrderDetails(Order order) {
    Navigator.pushNamed(
      context,
      '/product-detail-screen',
      arguments: {'order': order},
    );
  }

  void _showStatusUpdateDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => StatusUpdateDialog(
        currentStatus: order.status,
        onStatusUpdate: (newStatus) => _updateOrderStatus(order, newStatus),
      ),
    );
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(
        orderId: order.id,
        newStatus: newStatus,
      );

      // Update local data
      final index = allOrders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        setState(() {
          allOrders[index] = order.copyWith(status: newStatus);
        });
      }

      Fluttertoast.showToast(
        msg: "Order status updated to $newStatus",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to update order status",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _generateInvoice(Order order) {
    Fluttertoast.showToast(
      msg: "Generating invoice for Order #${order.orderNumber}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _showFilterOptions() {
    Fluttertoast.showToast(
      msg: "Filter options",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _showBulkActions() {
    Fluttertoast.showToast(
      msg: "Bulk actions",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Order Management'),
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () =>
              Navigator.pushNamed(context, '/seller-dashboard-screen'),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.foregroundDark,
            size: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshOrders,
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.foregroundDark,
              size: 24,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            OrderSearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onFilterTap: _showFilterOptions,
              hasActiveFilters: hasActiveFilters,
            ),

            // Status Filter Chips
            Container(
              height: 6.h,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: statusFilters.length,
                separatorBuilder: (context, index) => SizedBox(width: 2.w),
                itemBuilder: (context, index) {
                  final status = statusFilters[index];
                  return OrderStatusChip(
                    status: status,
                    isSelected: selectedStatus == status,
                    onTap: () => _onStatusFilterChanged(status),
                  );
                },
              ),
            ),

            // Orders List
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryEmerald,
                      ),
                    )
                  : filteredOrders.isEmpty
                      ? EmptyOrdersWidget(
                          message: searchQuery.isNotEmpty
                              ? 'No orders found matching "$searchQuery"'
                              : selectedStatus != 'All'
                                  ? 'No $selectedStatus orders found'
                                  : 'No orders available. Start by adding products to your store.',
                          onRefresh: _refreshOrders,
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshOrders,
                          color: AppTheme.primaryEmerald,
                          child: ListView.builder(
                            padding: EdgeInsets.only(bottom: 10.h),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              // Convert Order to Map for widget compatibility
                              final orderData = {
                                'id': order.id,
                                'orderNumber': order.orderNumber,
                                'customerName': 'Customer',
                                'customerPhone': order.customerPhone,
                                'orderDate':
                                    '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                                'totalAmount':
                                    '₹${order.totalAmount.toStringAsFixed(0)}',
                                'status': order.status,
                                'items': order.items
                                    .map((item) => {
                                          'name':
                                              item.product?.name ?? 'Product',
                                          'quantity':
                                              '${item.quantity} ${item.product?.unit ?? 'pcs'}',
                                          'price':
                                              '₹${item.totalPrice.toStringAsFixed(0)}',
                                        })
                                    .toList(),
                                'address': order.deliveryAddress,
                              };

                              return OrderCard(
                                order: orderData,
                                onTap: () => _viewOrderDetails(order),
                                onContactCustomer: () =>
                                    _contactCustomer(order),
                                onShowActions: () => _showOrderActions(order),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: filteredOrders.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBulkActions,
              backgroundColor: AppTheme.primaryEmerald,
              foregroundColor: AppTheme.cardWhite,
              icon: CustomIconWidget(
                iconName: 'checklist',
                color: AppTheme.cardWhite,
                size: 20,
              ),
              label: Text(
                'Bulk Actions',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.cardWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1, // Orders tab active
        selectedItemColor: AppTheme.primaryEmerald,
        unselectedItemColor: AppTheme.mutedText,
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'dashboard',
              color: AppTheme.mutedText,
              size: 24,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'dashboard',
              color: AppTheme.primaryEmerald,
              size: 24,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'shopping_bag',
              color: AppTheme.primaryEmerald,
              size: 24,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'shopping_bag',
              color: AppTheme.primaryEmerald,
              size: 24,
            ),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'inventory',
              color: AppTheme.mutedText,
              size: 24,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'inventory',
              color: AppTheme.primaryEmerald,
              size: 24,
            ),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person',
              color: AppTheme.mutedText,
              size: 24,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'person',
              color: AppTheme.primaryEmerald,
              size: 24,
            ),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/seller-dashboard-screen');
              break;
            case 1:
              // Already on Orders screen
              break;
            case 2:
              Navigator.pushNamed(context, '/add-product-screen');
              break;
            case 3:
              Navigator.pushNamed(context, '/role-selection-screen');
              break;
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
