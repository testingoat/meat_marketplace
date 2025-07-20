import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class InventorySectionWidget extends StatefulWidget {
  final TextEditingController stockController;
  final String selectedUnit;
  final bool isAvailable;
  final Function(String) onUnitChanged;
  final Function(bool) onAvailabilityChanged;

  const InventorySectionWidget({
    Key? key,
    required this.stockController,
    required this.selectedUnit,
    required this.isAvailable,
    required this.onUnitChanged,
    required this.onAvailabilityChanged,
  }) : super(key: key);

  @override
  State<InventorySectionWidget> createState() => _InventorySectionWidgetState();
}

class _InventorySectionWidgetState extends State<InventorySectionWidget> {
  final List<Map<String, dynamic>> _units = [
    {'value': 'kg', 'label': 'Kilogram (kg)', 'icon': 'scale'},
    {'value': 'piece', 'label': 'Piece', 'icon': 'inventory'},
    {'value': 'pack', 'label': 'Pack', 'icon': 'inventory_2'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'inventory',
                color: AppTheme.primaryEmerald,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Inventory Management',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Stock Quantity
          TextFormField(
            controller: widget.stockController,
            decoration: InputDecoration(
              labelText: 'Stock Quantity *',
              hintText: 'Enter available quantity',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'numbers',
                  color: AppTheme.mutedText,
                  size: 20,
                ),
              ),
              suffixText: widget.selectedUnit,
              suffixStyle: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Stock quantity is required';
              }
              final quantity = double.tryParse(value);
              if (quantity == null) {
                return 'Please enter a valid quantity';
              }
              if (quantity <= 0) {
                return 'Quantity must be greater than 0';
              }
              return null;
            },
          ),
          SizedBox(height: 3.h),

          // Unit Type Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unit Type *',
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _units.map((unit) {
                    final isSelected = widget.selectedUnit == unit['value'];
                    return InkWell(
                      onTap: () => widget.onUnitChanged(unit['value']),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.accentLight
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryEmerald
                                    : AppTheme.accentLight,
                                shape: BoxShape.circle,
                              ),
                              child: CustomIconWidget(
                                iconName: unit['icon'],
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.mutedText,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    unit['label'],
                                    style: AppTheme
                                        .lightTheme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppTheme.primaryEmerald
                                          : AppTheme
                                              .lightTheme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (unit['value'] == 'kg')
                                    Text(
                                      'Best for meat products sold by weight',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppTheme.mutedText,
                                      ),
                                    )
                                  else if (unit['value'] == 'piece')
                                    Text(
                                      'For individual items like whole chicken',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppTheme.mutedText,
                                      ),
                                    )
                                  else
                                    Text(
                                      'For packaged products',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppTheme.mutedText,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              CustomIconWidget(
                                iconName: 'check_circle',
                                color: AppTheme.primaryEmerald,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Availability Toggle
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: widget.isAvailable
                  ? AppTheme.accentLight
                  : AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isAvailable
                    ? AppTheme.primaryEmerald
                    : AppTheme.borderSubtle,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: widget.isAvailable
                        ? AppTheme.primaryEmerald
                        : AppTheme.mutedText,
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: widget.isAvailable ? 'check' : 'close',
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Availability',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.isAvailable
                            ? 'Product is available for orders'
                            : 'Product is currently out of stock',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.isAvailable,
                  onChanged: widget.onAvailabilityChanged,
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // Stock Management Tips
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'tips_and_updates',
                      color: AppTheme.primaryEmerald,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Stock Management Tips',
                      style:
                          AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  '• Update stock regularly to avoid overselling\n• Set realistic quantities based on daily supply\n• Turn off availability when out of stock\n• Consider minimum order quantities',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
