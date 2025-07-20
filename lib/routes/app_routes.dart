import 'package:flutter/material.dart';
import '../presentation/role_selection_screen/role_selection_screen.dart';
import '../presentation/order_management_screen/order_management_screen.dart';
import '../presentation/seller_dashboard_screen/seller_dashboard_screen.dart';
import '../presentation/otp_verification_screen/otp_verification_screen.dart';
import '../presentation/product_detail_screen/product_detail_screen.dart';
import '../presentation/add_product_screen/add_product_screen.dart';
import '../presentation/odoo_integration_screen/odoo_integration_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String roleSelectionScreen = '/role-selection-screen';
  static const String orderManagementScreen = '/order-management-screen';
  static const String sellerDashboardScreen = '/seller-dashboard-screen';
  static const String otpVerificationScreen = '/otp-verification-screen';
  static const String productDetailScreen = '/product-detail-screen';
  static const String addProductScreen = '/add-product-screen';
  static const String odooIntegrationScreen = '/odoo-integration-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => RoleSelectionScreen(),
    roleSelectionScreen: (context) => RoleSelectionScreen(),
    orderManagementScreen: (context) => OrderManagementScreen(),
    sellerDashboardScreen: (context) => SellerDashboardScreen(),
    otpVerificationScreen: (context) => OtpVerificationScreen(),
    productDetailScreen: (context) => ProductDetailScreen(),
    addProductScreen: (context) => AddProductScreen(),
    odooIntegrationScreen: (context) => OdooIntegrationScreen(),
    // TODO: Add your other routes here
  };
}
