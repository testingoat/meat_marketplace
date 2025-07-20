import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/odoo_sync_service.dart';

class SyncLogsCard extends StatelessWidget {
  final SyncResult? lastSyncResult;
  final DateTime? lastSyncTime;

  const SyncLogsCard({
    Key? key,
    required this.lastSyncResult,
    required this.lastSyncTime,
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
          Row(
            children: [
              Icon(
                Icons.history,
                color: Color(0xFF2B5CE6),
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Sync Logs',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              if (lastSyncTime != null)
                Text(
                  _formatDateTime(lastSyncTime!),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),

          SizedBox(height: 3.h),

          if (lastSyncResult != null) ...[
            // Success summary
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: lastSyncResult!.success
                    ? Color(0xFF10B981).withAlpha(26)
                    : Color(0xFFEF4444).withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: lastSyncResult!.success
                      ? Color(0xFF10B981).withAlpha(77)
                      : Color(0xFFEF4444).withAlpha(77),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    lastSyncResult!.success ? Icons.check_circle : Icons.error,
                    color: lastSyncResult!.success
                        ? Color(0xFF10B981)
                        : Color(0xFFEF4444),
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lastSyncResult!.success
                              ? 'Sync Completed'
                              : 'Sync Failed',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: lastSyncResult!.success
                                ? Color(0xFF10B981)
                                : Color(0xFFEF4444),
                          ),
                        ),
                        if (!lastSyncResult!.success &&
                            lastSyncResult!.error != null)
                          Text(
                            lastSyncResult!.error!,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.h),

            // Activity details
            Text(
              'Activity Details',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),

            SizedBox(height: 1.h),

            // Activity list
            ...([
              if (lastSyncResult!.productsSynced > 0)
                _buildLogEntry(
                  icon: Icons.inventory,
                  title: 'Products Synced',
                  description:
                      '${lastSyncResult!.productsSynced} products synchronized with Odoo',
                  type: LogEntryType.success,
                  time: lastSyncTime,
                ),

              if (lastSyncResult!.productsUpdated > 0)
                _buildLogEntry(
                  icon: Icons.update,
                  title: 'Products Updated',
                  description:
                      '${lastSyncResult!.productsUpdated} products updated in Odoo',
                  type: LogEntryType.info,
                  time: lastSyncTime,
                ),

              if (lastSyncResult!.inventoryUpdated > 0)
                _buildLogEntry(
                  icon: Icons.inventory_2,
                  title: 'Inventory Updated',
                  description:
                      '${lastSyncResult!.inventoryUpdated} inventory records updated',
                  type: LogEntryType.info,
                  time: lastSyncTime,
                ),

              if (lastSyncResult!.ordersSynced > 0)
                _buildLogEntry(
                  icon: Icons.shopping_cart,
                  title: 'Orders Synced',
                  description:
                      '${lastSyncResult!.ordersSynced} orders synchronized with Odoo',
                  type: LogEntryType.success,
                  time: lastSyncTime,
                ),

              if (lastSyncResult!.customersSynced > 0)
                _buildLogEntry(
                  icon: Icons.people,
                  title: 'Customers Synced',
                  description:
                      '${lastSyncResult!.customersSynced} customers synchronized with Odoo',
                  type: LogEntryType.success,
                  time: lastSyncTime,
                ),

              // Show errors
              ...lastSyncResult!.errors
                  .map((error) => _buildLogEntry(
                        icon: Icons.error,
                        title: 'Error',
                        description: error,
                        type: LogEntryType.error,
                        time: lastSyncTime,
                      ))
                  .toList(),
            ]),

            if (lastSyncResult!.productsSynced == 0 &&
                lastSyncResult!.ordersSynced == 0 &&
                lastSyncResult!.errors.isEmpty) ...[
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'No changes to sync. All data is up to date.',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            // No sync results yet
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    color: Colors.grey[400],
                    size: 40,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'No sync logs available',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Run your first sync to see activity logs here',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 2.h),

          // Clear logs button
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                _showClearLogsDialog(context);
              },
              icon: Icon(Icons.clear_all, size: 16),
              label: Text(
                'Clear Logs',
                style: GoogleFonts.inter(fontSize: 12.sp),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry({
    required IconData icon,
    required String title,
    required String description,
    required LogEntryType type,
    DateTime? time,
  }) {
    Color color;
    Color backgroundColor;

    switch (type) {
      case LogEntryType.success:
        color = Color(0xFF10B981);
        backgroundColor = Color(0xFF10B981).withAlpha(26);
        break;
      case LogEntryType.error:
        color = Color(0xFFEF4444);
        backgroundColor = Color(0xFFEF4444).withAlpha(26);
        break;
      case LogEntryType.warning:
        color = Color(0xFFFBBF24);
        backgroundColor = Color(0xFFFBBF24).withAlpha(26);
        break;
      case LogEntryType.info:
        color = Color(0xFF3B82F6);
        backgroundColor = Color(0xFF3B82F6).withAlpha(26);
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(51),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    if (time != null)
                      Text(
                        _formatTime(time),
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showClearLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Logs',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to clear all sync logs? This action cannot be undone.',
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
              // Clear logs logic would go here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }
}

enum LogEntryType { success, error, warning, info }
