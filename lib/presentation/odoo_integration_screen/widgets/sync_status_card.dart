import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../services/odoo_sync_service.dart';

class SyncStatusCard extends StatelessWidget {
  final SyncStatus? syncStatus;
  final DateTime? lastSyncTime;
  final SyncResult? lastSyncResult;
  final VoidCallback onSync;
  final bool isLoading;

  const SyncStatusCard({
    Key? key,
    required this.syncStatus,
    required this.lastSyncTime,
    required this.lastSyncResult,
    required this.onSync,
    required this.isLoading,
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
          // Header with connection status
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor().withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      _getStatusText(),
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLoading)
                ElevatedButton(
                  onPressed: onSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2B5CE6),
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync, size: 16),
                      SizedBox(width: 1.w),
                      Text(
                        'Sync Now',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          SizedBox(height: 3.h),

          // Sync statistics
          if (lastSyncResult != null) ...[
            Text(
              'Last Sync Results',
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
                  child: _buildStatCard(
                    'Products Synced',
                    lastSyncResult!.productsSynced.toString(),
                    Icons.inventory,
                    Color(0xFF10B981),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildStatCard(
                    'Orders Synced',
                    lastSyncResult!.ordersSynced.toString(),
                    Icons.shopping_cart,
                    Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.w),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Inventory Updated',
                    lastSyncResult!.inventoryUpdated.toString(),
                    Icons.update,
                    Color(0xFFEF4444),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildStatCard(
                    'Errors',
                    lastSyncResult!.errors.length.toString(),
                    Icons.error_outline,
                    lastSyncResult!.errors.isEmpty
                        ? Color(0xFF6B7280)
                        : Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],

          // Last sync time
          if (lastSyncTime != null) ...[
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Last synced: ${_formatDateTime(lastSyncTime!)}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Auto-sync status
          if (syncStatus != null) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: syncStatus!.autoSyncEnabled
                    ? Color(0xFF10B981).withAlpha(26)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: syncStatus!.autoSyncEnabled
                      ? Color(0xFF10B981).withAlpha(77)
                      : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    syncStatus!.autoSyncEnabled
                        ? Icons.sync
                        : Icons.sync_disabled,
                    color: syncStatus!.autoSyncEnabled
                        ? Color(0xFF10B981)
                        : Colors.grey[600],
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    syncStatus!.autoSyncEnabled
                        ? 'Auto-sync is enabled'
                        : 'Auto-sync is disabled',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: syncStatus!.autoSyncEnabled
                          ? Color(0xFF10B981)
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (syncStatus == null) return Colors.grey;

    if (syncStatus!.isSyncing) return Color(0xFFFBBF24);

    return syncStatus!.isConnected ? Color(0xFF10B981) : Color(0xFFEF4444);
  }

  IconData _getStatusIcon() {
    if (syncStatus == null) return Icons.help_outline;

    if (syncStatus!.isSyncing) return Icons.sync;

    return syncStatus!.isConnected ? Icons.check_circle : Icons.error;
  }

  String _getStatusText() {
    if (syncStatus == null) return 'Unknown';

    if (syncStatus!.isSyncing) return 'Syncing...';

    return syncStatus!.isConnected ? 'Connected' : 'Disconnected';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
