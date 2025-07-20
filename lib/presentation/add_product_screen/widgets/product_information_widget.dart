import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class ProductInformationWidget extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final String selectedCategory;
  final Function(String) onCategoryChanged;
  final GlobalKey<FormState> formKey;

  const ProductInformationWidget({
    Key? key,
    required this.nameController,
    required this.descriptionController,
    required this.priceController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.formKey,
  }) : super(key: key);

  @override
  State<ProductInformationWidget> createState() =>
      _ProductInformationWidgetState();
}

class _ProductInformationWidgetState extends State<ProductInformationWidget> {
  final List<Map<String, String>> _categories = [
    {'value': 'chicken', 'label': 'Chicken', 'icon': 'restaurant'},
    {'value': 'mutton', 'label': 'Mutton', 'icon': 'restaurant'},
    {'value': 'fish', 'label': 'Fish', 'icon': 'set_meal'},
    {'value': 'seafood', 'label': 'Seafood', 'icon': 'set_meal'},
    {'value': 'pork', 'label': 'Pork', 'icon': 'restaurant'},
    {'value': 'beef', 'label': 'Beef', 'icon': 'restaurant'},
    {'value': 'others', 'label': 'Others', 'icon': 'category'},
  ];
  bool _isDescriptionExpanded = false;

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
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: AppTheme.primaryEmerald,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Product Information',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Product Name
            TextFormField(
              controller: widget.nameController,
              decoration: InputDecoration(
                labelText: 'Product Name *',
                hintText: 'Enter product name',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'shopping_bag',
                    color: AppTheme.mutedText,
                    size: 20,
                  ),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Product name is required';
                }
                if (value.trim().length < 3) {
                  return 'Product name must be at least 3 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 3.h),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: widget.selectedCategory.isNotEmpty
                  ? widget.selectedCategory
                  : null,
              decoration: InputDecoration(
                labelText: 'Category *',
                hintText: 'Select category',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'category',
                    color: AppTheme.mutedText,
                    size: 20,
                  ),
                ),
              ),
              items: _categories.map((Map<String, String> category) {
                return DropdownMenuItem<String>(
                  value: category['value'],
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: category['icon']!,
                        color: AppTheme.primaryEmerald,
                        size: 18,
                      ),
                      SizedBox(width: 2.w),
                      Text(category['label']!),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  widget.onCategoryChanged(newValue);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            SizedBox(height: 3.h),

            // Description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: widget.descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Describe your product...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'description',
                        color: AppTheme.mutedText,
                        size: 20,
                      ),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      icon: CustomIconWidget(
                        iconName: _isDescriptionExpanded
                            ? 'expand_less'
                            : 'expand_more',
                        color: AppTheme.mutedText,
                        size: 20,
                      ),
                    ),
                  ),
                  maxLines: _isDescriptionExpanded ? 6 : 3,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Product description is required';
                    }
                    if (value.trim().length < 20) {
                      return 'Description must be at least 20 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 1.h),
                Text(
                  'Include details about quality, origin, freshness, and any special features',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Price per Kg
            TextFormField(
              controller: widget.priceController,
              decoration: InputDecoration(
                labelText: 'Price per Kg *',
                hintText: '0.00',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                suffixText: 'per kg',
                suffixStyle: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                ),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Price is required';
                }
                final price = double.tryParse(value);
                if (price == null) {
                  return 'Please enter a valid price';
                }
                if (price <= 0) {
                  return 'Price must be greater than 0';
                }
                if (price > 10000) {
                  return 'Price seems too high. Please verify';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),

            // Price Guidelines
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
                        iconName: 'lightbulb',
                        color: AppTheme.primaryEmerald,
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Pricing Guidelines',
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
                    '• Research market prices in your area\n• Consider quality and freshness\n• Include GST in your pricing\n• Competitive pricing attracts more customers',
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
      ),
    );
  }
}
