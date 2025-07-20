import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class ReviewsSection extends StatelessWidget {
  final Map<String, dynamic> reviewSummary;
  final List<Map<String, dynamic>> reviews;

  const ReviewsSection({
    super.key,
    required this.reviewSummary,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Customer Reviews",
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      "${reviewSummary["averageRating"]}",
                      style: AppTheme.lightTheme.textTheme.headlineMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return CustomIconWidget(
                              iconName: index <
                                      (reviewSummary["averageRating"] as double)
                                          .floor()
                                  ? 'star'
                                  : 'star_border',
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          "Based on ${reviewSummary["totalReviews"]} reviews",
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildRatingBreakdown(),
              ],
            ),
          ),
          Divider(color: AppTheme.borderSubtle, height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(4.w),
            itemCount: reviews.length > 3 ? 3 : reviews.length,
            separatorBuilder: (context, index) => Divider(
              color: AppTheme.borderSubtle,
              height: 3.h,
            ),
            itemBuilder: (context, index) {
              return _buildReviewItem(reviews[index]);
            },
          ),
          if (reviews.length > 3)
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
              child: TextButton(
                onPressed: () => _showAllReviews(context),
                child: Text(
                  "View all ${reviews.length} reviews",
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryEmerald,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingBreakdown() {
    final Map<int, int> ratingCounts =
        reviewSummary["ratingBreakdown"] as Map<int, int>;
    final int totalReviews = reviewSummary["totalReviews"] as int;

    return Column(
      children: List.generate(5, (index) {
        final rating = 5 - index;
        final count = ratingCounts[rating] ?? 0;
        final percentage = totalReviews > 0 ? (count / totalReviews) : 0.0;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 0.5.h),
          child: Row(
            children: [
              Text(
                "$rating",
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
              SizedBox(width: 1.w),
              CustomIconWidget(
                iconName: 'star',
                color: Colors.amber,
                size: 12,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Container(
                  height: 0.8.h,
                  decoration: BoxDecoration(
                    color: AppTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                "$count",
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.accentLight,
              child: Text(
                (review["customerName"] as String)
                    .substring(0, 1)
                    .toUpperCase(),
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryEmerald,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review["customerName"] as String,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return CustomIconWidget(
                            iconName: index < (review["rating"] as int)
                                ? 'star'
                                : 'star_border',
                            color: Colors.amber,
                            size: 14,
                          );
                        }),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        _formatDate(review["date"] as DateTime),
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          review["comment"] as String,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            height: 1.4,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "Today";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  void _showAllReviews(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "All Reviews (${reviews.length})",
                          style: AppTheme.lightTheme.textTheme.titleLarge
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: CustomIconWidget(
                          iconName: 'close',
                          color: AppTheme.mutedText,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: AppTheme.borderSubtle, height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: EdgeInsets.all(4.w),
                    itemCount: reviews.length,
                    separatorBuilder: (context, index) => Divider(
                      color: AppTheme.borderSubtle,
                      height: 3.h,
                    ),
                    itemBuilder: (context, index) {
                      return _buildReviewItem(reviews[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
