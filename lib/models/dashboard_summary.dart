import 'category_summary.dart';

/// Response shape of `GET /api/dashboard/summary`.
class DashboardSummary {
  const DashboardSummary({
    required this.totalThisMonth,
    required this.categories,
  });

  final double totalThisMonth;
  final List<CategorySummary> categories;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        totalThisMonth: (json['totalThisMonth'] as num).toDouble(),
        categories: (json['categories'] as List<dynamic>? ?? const [])
            .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
