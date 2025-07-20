import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/odoo_sync_service.dart';

class SyncSettingsCard extends StatelessWidget {
  final SyncStatus? syncStatus;
  final Function(bool) onAutoSyncToggle;
  final VoidCallback onReconfigure;

  const SyncSettingsCard({
    Key? key,
    required this.syncStatus,
    required this.onAutoSyncToggle,
    required this.onReconfigure,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Sync Settings',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),

          SizedBox(height: 3.h),

          // Auto-sync toggle
          _buildSettingTile(
            icon: Icons.sync,
            title: 'Auto Sync',
            subtitle: 'Automatically sync data with Odoo ERP',
            trailing: Switch(
              value: syncStatus?.autoSyncEnabled ?? false,
              onChanged: onAutoSyncToggle,
              activeColor: Color(0xFF10B981),
            ),
          ),

          Divider(height: 3.h, color: Colors.grey[200]),

          // Sync interval settings
          _buildSettingTile(
            icon: Icons.schedule,
            title: 'Sync Interval',
            subtitle: 'How often to sync automatically',
            trailing: DropdownButton<int>(
              value: 30, // Default 30 minutes
              underline: SizedBox(),
              items: [
                DropdownMenuItem(value: 15, child: Text('15 min')),
                DropdownMenuItem(value: 30, child: Text('30 min')),
                DropdownMenuItem(value: 60, child: Text('1 hour')),
                DropdownMenuItem(value: 120, child: Text('2 hours')),
              ],
              onChanged: (value) {
                if (value != null) {
                  // Update sync interval
                }
              },
            ),
          ),

          Divider(height: 3.h, color: Colors.grey[200]),

          // Sync on connectivity change
          _buildSettingTile(
            icon: Icons.wifi,
            title: 'Sync on Network Change',
            subtitle: 'Sync when network connection is restored',
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // Toggle connectivity sync
              },
              activeColor: Color(0xFF10B981),
            ),
          ),

          Divider(height: 3.h, color: Colors.grey[200]),

          // Webhook notifications
          _buildSettingTile(
            icon: Icons.notifications,
            title: 'Webhook Notifications',
            subtitle: 'Receive real-time updates from Odoo',
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // Toggle webhook notifications
              },
              activeColor: Color(0xFF10B981),
            ),
          ),

          SizedBox(height: 3.h),

          // Configuration section
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuration',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onReconfigure,
                        icon: Icon(Icons.settings, size: 16),
                        label: Text(
                          'Reconfigure Odoo',
                          style: GoogleFonts.inter(fontSize: 12.sp),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2B5CE6),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showTestConnectionDialog(context);
                        },
                        icon: Icon(Icons.link, size: 16),
                        label: Text(
                          'Test Connection',
                          style: GoogleFonts.inter(fontSize: 12.sp),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFF2B5CE6),
                          side: BorderSide(color: Color(0xFF2B5CE6)),
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // Danger zone
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Color(0xFFEF4444).withAlpha(26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFEF4444).withAlpha(77)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Danger Zone',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  'Disconnect from Odoo ERP. This will stop all synchronization.',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 1.h),
                OutlinedButton(
                  onPressed: () {
                    _showDisconnectDialog(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFFEF4444),
                    side: BorderSide(color: Color(0xFFEF4444)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Disconnect from Odoo',
                    style: GoogleFonts.inter(fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF2B5CE6).withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Color(0xFF2B5CE6),
            size: 18,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }

  void _showTestConnectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Test Connection',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 2.h),
            Text(
              'Testing connection to Odoo ERP...',
              style: GoogleFonts.inter(fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );

    // Simulate connection test
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Connection Test',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF10B981)),
              SizedBox(width: 2.w),
              Text(
                'Connection successful!',
                style: GoogleFonts.inter(fontSize: 14.sp),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  void _showDisconnectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Disconnect from Odoo',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to disconnect from Odoo ERP? This will stop all synchronization and you will need to reconfigure the connection.',
          style: GoogleFonts.inter(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onReconfigure();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
