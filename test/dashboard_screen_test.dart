import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:budget_tracker_flutter/data/auth_repository.dart';
import 'package:budget_tracker_flutter/data/category_repository.dart';
import 'package:budget_tracker_flutter/data/dashboard_repository.dart';
import 'package:budget_tracker_flutter/data/expense_repository.dart';
import 'package:budget_tracker_flutter/models/budget_status.dart';
import 'package:budget_tracker_flutter/models/category_summary.dart';
import 'package:budget_tracker_flutter/models/dashboard_summary.dart';
import 'package:budget_tracker_flutter/models/expense.dart';
import 'package:budget_tracker_flutter/state/auth_state.dart';
import 'package:budget_tracker_flutter/state/dashboard_state.dart';
import 'package:budget_tracker_flutter/state/expenses_state.dart';
import 'package:budget_tracker_flutter/ui/screens/dashboard_screen.dart';
import 'package:budget_tracker_flutter/ui/widgets/category_progress_bar.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDashboardRepository extends Mock implements DashboardRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockDashboardRepository dashboardRepository;
  late MockExpenseRepository expenseRepository;
  late MockCategoryRepository categoryRepository;

  const summary = DashboardSummary(
    totalThisMonth: 321.5,
    categories: [
      CategorySummary(
        categoryId: 1,
        categoryName: 'Comida',
        monthlyLimit: 500,
        spent: 100,
        remaining: 400,
        percentUsed: 20, // OK -> green
        status: 'OK',
      ),
      CategorySummary(
        categoryId: 2,
        categoryName: 'Transporte',
        monthlyLimit: 200,
        spent: 140,
        remaining: 60,
        percentUsed: 70, // WARNING -> amber
        status: 'WARNING',
      ),
      CategorySummary(
        categoryId: 3,
        categoryName: 'Ocio',
        monthlyLimit: 100,
        spent: 120,
        remaining: -20,
        percentUsed: 120, // OVER -> red
        status: 'OVER',
      ),
    ],
  );

  setUp(() {
    authRepository = MockAuthRepository();
    dashboardRepository = MockDashboardRepository();
    expenseRepository = MockExpenseRepository();
    categoryRepository = MockCategoryRepository();

    when(() => dashboardRepository.getSummary()).thenAnswer((_) async => summary);
    when(() => expenseRepository.getExpenses()).thenAnswer(
      (_) async => [
        Expense(
          id: 1,
          categoryId: 1,
          categoryName: 'Comida',
          amount: 12.5,
          description: 'Almuerzo',
          date: DateTime(2026, 9, 30),
        ),
      ],
    );
    when(() => categoryRepository.getCategories()).thenAnswer((_) async => []);
    when(() => authRepository.logout()).thenAnswer((_) async {});
    when(() => authRepository.hasValidSession()).thenAnswer((_) async => false);
  });

  Widget buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>(
          create: (_) => AuthState(authRepository: authRepository),
        ),
        ChangeNotifierProvider<DashboardState>(
          create: (_) => DashboardState(dashboardRepository: dashboardRepository),
        ),
        ChangeNotifierProvider<ExpensesState>(
          create: (_) => ExpensesState(
            expenseRepository: expenseRepository,
            categoryRepository: categoryRepository,
          ),
        ),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    );
  }

  testWidgets('renders total, categories and recent expenses', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('total_this_month_text')), findsOneWidget);
    expect(find.text('\$321.50'), findsOneWidget);
    expect(find.text('Comida'), findsWidgets);
    expect(find.text('Transporte'), findsOneWidget);
    expect(find.text('Ocio'), findsOneWidget);
    expect(find.text('Almuerzo'), findsOneWidget);
  });

  testWidgets('colours each category progress bar by its OK/WARNING/OVER status', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final okBar = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('category_progress_1')),
    );
    final warningBar = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('category_progress_2')),
    );
    final overBar = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('category_progress_3')),
    );

    expect(okBar.valueColor!.value, CategoryProgressBar.colorFor(BudgetStatus.ok));
    expect(warningBar.valueColor!.value, CategoryProgressBar.colorFor(BudgetStatus.warning));
    expect(overBar.valueColor!.value, CategoryProgressBar.colorFor(BudgetStatus.over));
  });

  testWidgets('deleting an expense calls the repository', (tester) async {
    when(() => expenseRepository.deleteExpense(1)).thenAnswer((_) async {});

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.drag(find.byKey(const Key('expense_item_1')), const Offset(-500, 0));
    await tester.pumpAndSettle();

    verify(() => expenseRepository.deleteExpense(1)).called(1);
  });
}
