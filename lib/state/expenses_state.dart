// `Category` is hidden because it clashes with our own models/category.dart
// `Category` class; we don't use Flutter's test-annotation `Category` here.
import 'package:flutter/foundation.dart' hide Category;

import '../data/api_exception.dart';
import '../data/category_repository.dart';
import '../data/expense_repository.dart';
import '../models/category.dart';
import '../models/expense.dart';

/// Owns the expense list and the category list used to populate the expense
/// form's dropdown, plus the create/update/delete operations.
///
/// Both [DashboardScreen] (recent expenses + delete) and
/// [ExpenseFormScreen] (category dropdown + submit) share this one notifier
/// so the list is always consistent after an add/edit/delete, without each
/// screen re-fetching independently.
class ExpensesState extends ChangeNotifier {
  ExpensesState({
    required ExpenseRepository expenseRepository,
    required CategoryRepository categoryRepository,
  })  : _expenseRepository = expenseRepository,
        _categoryRepository = categoryRepository;

  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;

  List<Expense> expenses = [];
  List<Category> categories = [];
  bool isLoading = false;
  String? errorMessage;

  /// Expenses sorted most-recent-first, for the dashboard's "recent
  /// expenses" list.
  List<Expense> get recentExpenses {
    final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _expenseRepository.getExpenses(),
        _categoryRepository.getCategories(),
      ]);
      expenses = results[0] as List<Expense>;
      categories = results[1] as List<Category>;
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Could not load expenses: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      categories = await _categoryRepository.getCategories();
      notifyListeners();
    } on ApiException catch (e) {
      errorMessage = e.message;
      notifyListeners();
    }
  }

  /// Creates or updates an expense depending on whether [expense.id] is set.
  /// Throws [ApiException] on failure; callers (the form screen) catch it to
  /// show an inline error instead of crashing.
  Future<Expense> submit(Expense expense) async {
    final Expense saved;
    if (expense.id == null) {
      saved = await _expenseRepository.createExpense(expense);
      expenses = [...expenses, saved];
    } else {
      saved = await _expenseRepository.updateExpense(expense.id!, expense);
      expenses = [
        for (final e in expenses) if (e.id == saved.id) saved else e,
      ];
    }
    notifyListeners();
    return saved;
  }

  Future<void> delete(int id) async {
    await _expenseRepository.deleteExpense(id);
    expenses = expenses.where((e) => e.id != id).toList();
    notifyListeners();
  }
}
