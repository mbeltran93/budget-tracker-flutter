import 'package:flutter/material.dart';

import '../../models/budget_status.dart';
import '../../models/category_summary.dart';

/// Renders one category's spending progress bar, coloured green / yellow /
/// red using the exact same OK / WARNING / OVER thresholds the backend uses
/// (see [budgetStatusForPercent]), rather than trusting the raw `status`
/// string, so a future backend change in wording alone can't desync the
/// colour from the real percentage.
class CategoryProgressBar extends StatelessWidget {
  const CategoryProgressBar({super.key, required this.summary});

  final CategorySummary summary;

  static Color colorFor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.ok:
        return Colors.green;
      case BudgetStatus.warning:
        return Colors.amber;
      case BudgetStatus.over:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(summary.budgetStatus);
    final fraction = (summary.percentUsed / 100).clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                summary.categoryName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${summary.spent.toStringAsFixed(2)} / '
                '\$${summary.monthlyLimit.toStringAsFixed(2)}',
                key: Key('category_amounts_${summary.categoryId}'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: Key('category_progress_${summary.categoryId}'),
              value: fraction,
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${summary.percentUsed}% used · \$${summary.remaining.toStringAsFixed(2)} remaining',
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
