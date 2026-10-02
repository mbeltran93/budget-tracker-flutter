/// The three budget states a category can be in, with the exact thresholds
/// the backend uses to compute `DashboardSummary.categories[].status`:
///
/// - below 50% used  -> [ok]      (green)
/// - 50% to 99% used -> [warning] (yellow)
/// - 100% or more     -> [over]    (red)
///
/// Any client-side widget that draws its own progress bar (instead of just
/// switching on the raw `status` string from the server) must use
/// [budgetStatusForPercent] so the colour always matches the backend's rule.
enum BudgetStatus { ok, warning, over }

BudgetStatus budgetStatusForPercent(num percentUsed) {
  if (percentUsed >= 100) return BudgetStatus.over;
  if (percentUsed >= 50) return BudgetStatus.warning;
  return BudgetStatus.ok;
}
