import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../models/odoo_config.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_sync_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/odoo_config_form.dart';
import './widgets/sync_settings_card.dart';
import './widgets/sync_status_card.dart';

class OdooIntegrationScreen extends StatefulWidget {
  const OdooIntegrationScreen({Key? key}) : super(key: key);

  @override
  State<OdooIntegrationScreen> createState() => _OdooIntegrationScreenState();
}

class _OdooIntegrationScreenState extends State<OdooIntegrationScreen>
    with TickerProviderStateMixin {
  final OdooSyncService _syncService = OdooSyncService();
  final OdooService _odooService = OdooService();

  bool _isLoading = false;
  bool _isSyncing = false;
  SyncStatus? _syncStatus;
  DateTime? _lastSyncTime;
  String? _errorMessage;
  int _syncedProductsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _syncStatus = _syncService.getSyncStatus();
      _lastSyncTime = await _syncService.getLastSyncTimestamp();
    } catch (e) {
      print('Error loading sync status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerOdooSync() async {
    setState(() {
      _isSyncing = true;
      _errorMessage = null;
    });

    try {
      await _syncService.triggerOdooSync();

      final products = await _syncService.getOdooProducts();
      _syncedProductsCount = products.length;

      setState(() {
        _lastSyncTime = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Successfully synced $_syncedProductsCount products from Odoo'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3)));
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5)));
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
            title: Text('Odoo Integration'),
            leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: CustomIconWidget(
                    iconName: 'arrow_back',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24))),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadSyncStatus,
                child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SyncStatusCard(
                              syncStatus: _syncStatus,
                              lastSyncTime: _lastSyncTime,
                              isLoading: _isSyncing,
                              lastSyncResult: _errorMessage == null
                                  ? (SyncResult()
                                    ..success = true
                                    ..productsSynced = _syncedProductsCount)
                                  : (SyncResult()
                                    ..success = false
                                    ..error = _errorMessage),
                              onSync: _triggerOdooSync),
                          SizedBox(height: 3.h),
                          _buildQuickActionsCard(),
                          SizedBox(height: 3.h),
                          SyncSettingsCard(
                              syncStatus: _syncStatus,
                              onAutoSyncToggle: (value) {},
                              onReconfigure: () {}),
                          SizedBox(height: 3.h),
                          OdooConfigForm(
                              isLoading: _isLoading,
                              onConfigurationSaved: (OdooConfig config) {
                                _loadSyncStatus();
                              }),
                        ]))));
  }

  Widget _buildQuickActionsCard() {
    return Card(
        child: Padding(
            padding: EdgeInsets.all(4.w),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quick Actions',
                  style: AppTheme.lightTheme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: 2.h),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _triggerOdooSync,
                      icon: _isSyncing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white)))
                          : CustomIconWidget(
                              iconName: 'sync', color: Colors.white, size: 20),
                      label: Text(_isSyncing
                          ? 'Syncing...'
                          : 'Sync Products from Odoo'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryEmerald,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12)))),
              if (_syncedProductsCount > 0) ...[
                SizedBox(height: 1.h),
                Text('Last sync: $_syncedProductsCount products imported',
                    style: AppTheme.lightTheme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.successGreen)),
              ],
            ])));
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 0.5.h),
        child: Row(children: [
          Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
          SizedBox(width: 2.w),
          Expanded(
              child: Text(text,
                  style: GoogleFonts.inter(
                      fontSize: 12.sp, color: Colors.grey[700]))),
        ]));
  }

  Widget _buildQuickActions() {
    return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withAlpha(26),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2)),
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Quick Actions',
              style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800])),
          SizedBox(height: 2.h),
          Row(children: [
            Expanded(
                child: _buildActionButton(
                    icon: Icons.inventory,
                    title: 'Sync Products',
                    subtitle: 'Update product catalog',
                    onTap: () async {
                      await _triggerOdooSync();
                    })),
            SizedBox(width: 3.w),
            Expanded(
                child: _buildActionButton(
                    icon: Icons.shopping_cart,
                    title: 'Sync Orders',
                    subtitle: 'Update order status',
                    onTap: () async {
                      await _triggerOdooSync();
                    })),
          ]),
          SizedBox(height: 2.h),
          Row(children: [
            Expanded(
                child: _buildActionButton(
                    icon: Icons.analytics,
                    title: 'View Reports',
                    subtitle: 'Sales & inventory reports',
                    onTap: () {
                      Navigator.pushNamed(context, '/odoo-reports');
                    })),
            SizedBox(width: 3.w),
            Expanded(
                child: _buildActionButton(
                    icon: Icons.settings,
                    title: 'Configuration',
                    subtitle: 'Update ERP settings',
                    onTap: () {
                      // Navigate to configuration
                    })),
          ]),
        ]));
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
        onTap: _isLoading ? null : onTap,
        child: Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!)),
            child: Column(children: [
              Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Color(0xFF2B5CE6).withAlpha(26),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: Color(0xFF2B5CE6), size: 20)),
              SizedBox(height: 1.h),
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800]),
                  textAlign: TextAlign.center),
              Text(subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 10.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ])));
  }
}
