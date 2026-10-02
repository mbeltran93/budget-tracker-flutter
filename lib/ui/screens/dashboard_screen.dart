import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/expense.dart';
import '../../state/auth_state.dart';
import '../../state/dashboard_state.dart';
import '../../state/expenses_state.dart';
import '../widgets/category_progress_bar.dart';
import 'expense_form_screen.dart';
import 'login_screen.dart';

/// Home screen: total spent this month, a progress bar per category, a
/// recent-expenses list (editable/deletable), and logout.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Deferred to a microtask: the state notifiers call notifyListeners()
    // synchronously before their first await, and calling that during this
    // widget's own initial build (synchronously from initState) would hit
    // "setState() or markNeedsBuild() called during build".
    Future.microtask(_loadAll);
  }

  Future<void> _loadAll() async {
    await Future.wait([
      context.read<DashboardState>().load(),
      context.read<ExpensesState>().loadAll(),
    ]);
  }

  Future<void> _logout() async {
    await context.read<AuthState>().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _openForm({Expense? expense}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(existingExpense: expense),
      ),
    );
    // The form screen mutates ExpensesState directly, so re-fetch the
    // dashboard summary (totals/percentages) to stay in sync; the expense
    // list itself is already updated via the shared ExpensesState.
    if (mounted) {
      context.read<DashboardState>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardState>();
    final expensesState = context.watch<ExpensesState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            key: const Key('logout_button'),
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_expense_fab'),
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: _buildBody(dashboard, expensesState),
      ),
    );
  }

  Widget _buildBody(DashboardState dashboard, ExpensesState expensesState) {
    if (dashboard.isLoading && dashboard.summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dashboard.errorMessage != null && dashboard.summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dashboard.errorMessage!,
                key: const Key('dashboard_error_text'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadAll,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final summary = dashboard.summary;
    final recentExpenses = expensesState.recentExpenses.take(10).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (summary != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total this month'),
                  Text(
                    '\$${summary.totalThisMonth.toStringAsFixed(2)}',
                    key: const Key('total_this_month_text'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final categorySummary in summary.categories)
                    CategoryProgressBar(summary: categorySummary),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          'Recent expenses',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (recentExpenses.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No expenses yet.'),
          )
        else
          for (final expense in recentExpenses)
            Dismissible(
              key: Key('expense_item_${expense.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                if (expense.id != null) {
                  final expensesState = context.read<ExpensesState>();
                  final dashboardState = context.read<DashboardState>();
                  await expensesState.delete(expense.id!);
                  dashboardState.load();
                }
                return true;
              },
              child: ListTile(
                title: Text(expense.description),
                subtitle: Text(
                  '${expense.categoryName ?? ''} · ${Expense.formatDate(expense.date)}',
                ),
                trailing: Text('\$${expense.amount.toStringAsFixed(2)}'),
                onTap: () => _openForm(expense: expense),
              ),
            ),
      ],
    );
  }
}
