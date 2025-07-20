import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class AdditionalDetailsWidget extends StatefulWidget {
  final TextEditingController nutritionalInfoController;
  final TextEditingController preparationController;
  final TextEditingController storageController;

  const AdditionalDetailsWidget({
    Key? key,
    required this.nutritionalInfoController,
    required this.preparationController,
    required this.storageController,
  }) : super(key: key);

  @override
  State<AdditionalDetailsWidget> createState() =>
      _AdditionalDetailsWidgetState();
}

class _AdditionalDetailsWidgetState extends State<AdditionalDetailsWidget> {
  bool _isNutritionalExpanded = false;
  bool _isPreparationExpanded = false;
  bool _isStorageExpanded = false;

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
                iconName: 'more_horiz',
                color: AppTheme.primaryEmerald,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Additional Details',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Optional',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Nutritional Information
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: widget.nutritionalInfoController,
                decoration: InputDecoration(
                  labelText: 'Nutritional Information',
                  hintText: 'Protein, fat content, calories per 100g...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'local_dining',
                      color: AppTheme.mutedText,
                      size: 20,
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isNutritionalExpanded = !_isNutritionalExpanded;
                      });
                    },
                    icon: CustomIconWidget(
                      iconName: _isNutritionalExpanded
                          ? 'expand_less'
                          : 'expand_more',
                      color: AppTheme.mutedText,
                      size: 20,
                    ),
                  ),
                ),
                maxLines: _isNutritionalExpanded ? 4 : 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Example nutritional info:',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Protein: 26g, Fat: 15g, Calories: 250 per 100g\nRich in iron and vitamin B12\nNo artificial preservatives',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Preparation Instructions
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: widget.preparationController,
                decoration: InputDecoration(
                  labelText: 'Preparation Instructions',
                  hintText: 'Cooking tips, marination suggestions...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'restaurant_menu',
                      color: AppTheme.mutedText,
                      size: 20,
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isPreparationExpanded = !_isPreparationExpanded;
                      });
                    },
                    icon: CustomIconWidget(
                      iconName: _isPreparationExpanded
                          ? 'expand_less'
                          : 'expand_more',
                      color: AppTheme.mutedText,
                      size: 20,
                    ),
                  ),
                ),
                maxLines: _isPreparationExpanded ? 5 : 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Helpful preparation tips:',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '• Marinate for 2-4 hours for best flavor\n• Cook on medium heat for 15-20 minutes\n• Best served with rice or bread\n• Add spices according to taste',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Storage Guidelines
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: widget.storageController,
                decoration: InputDecoration(
                  labelText: 'Storage Guidelines',
                  hintText: 'Refrigeration, freezing, shelf life...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'ac_unit',
                      color: AppTheme.mutedText,
                      size: 20,
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isStorageExpanded = !_isStorageExpanded;
                      });
                    },
                    icon: CustomIconWidget(
                      iconName:
                          _isStorageExpanded ? 'expand_less' : 'expand_more',
                      color: AppTheme.mutedText,
                      size: 20,
                    ),
                  ),
                ),
                maxLines: _isStorageExpanded ? 4 : 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage recommendations:',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '• Refrigerate at 0-4°C immediately\n• Use within 2-3 days of purchase\n• Can be frozen for up to 3 months\n• Thaw in refrigerator before cooking',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Benefits Info
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomIconWidget(
                  iconName: 'star',
                  color: AppTheme.primaryEmerald,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why add these details?',
                        style:
                            AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryEmerald,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Detailed product information builds customer trust and helps them make informed decisions. This can lead to higher sales and better reviews.',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedText,
                          height: 1.3,
                        ),
                      ),
                    ],
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
