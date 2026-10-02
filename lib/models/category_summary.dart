import 'budget_status.dart';

/// One category's progress within `GET /api/dashboard/summary`:
/// `{"categoryId":1,"categoryName":"Comida","monthlyLimit":500.00,
///   "spent":123.45,"remaining":376.55,"percentUsed":25,"status":"OK"}`.
class CategorySummary {
  const CategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.monthlyLimit,
    required this.spent,
    required this.remaining,
    required this.percentUsed,
    required this.status,
  });

  final int categoryId;
  final String categoryName;
  final double monthlyLimit;
  final double spent;
  final double remaining;
  final num percentUsed;

  /// Raw status string from the backend ("OK" / "WARNING" / "OVER"), kept
  /// around for display/debugging, but [budgetStatus] (derived from
  /// [percentUsed]) is what the UI uses to decide colours.
  final String status;

  BudgetStatus get budgetStatus => budgetStatusForPercent(percentUsed);

  factory CategorySummary.fromJson(Map<String, dynamic> json) =>
      CategorySummary(
        categoryId: json['categoryId'] as int,
        categoryName: json['categoryName'] as String,
        monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
        remaining: (json['remaining'] as num).toDouble(),
        percentUsed: json['percentUsed'] as num,
        status: json['status'] as String,
      );
}
