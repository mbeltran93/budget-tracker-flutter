import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:budget_tracker_flutter/data/category_repository.dart';
import 'package:budget_tracker_flutter/data/expense_repository.dart';
import 'package:budget_tracker_flutter/models/category.dart';
import 'package:budget_tracker_flutter/models/expense.dart';
import 'package:budget_tracker_flutter/state/expenses_state.dart';
import 'package:budget_tracker_flutter/ui/screens/expense_form_screen.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockExpenseRepository expenseRepository;
  late MockCategoryRepository categoryRepository;

  setUpAll(() {
    registerFallbackValue(
      Expense(
        categoryId: 1,
        amount: 1,
        description: 'fallback',
        date: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    expenseRepository = MockExpenseRepository();
    categoryRepository = MockCategoryRepository();

    when(() => categoryRepository.getCategories()).thenAnswer(
      (_) async => const [
        Category(id: 1, name: 'Comida', monthlyLimit: 500),
        Category(id: 2, name: 'Transporte', monthlyLimit: 200),
      ],
    );
  });

  Widget buildApp({Expense? existingExpense}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ExpensesState>(
          create: (_) => ExpensesState(
            expenseRepository: expenseRepository,
            categoryRepository: categoryRepository,
          ),
        ),
      ],
      child: MaterialApp(
        home: ExpenseFormScreen(existingExpense: existingExpense),
      ),
    );
  }

  testWidgets('validates required fields before submitting', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('submit_expense_button')));
    await tester.pump();

    expect(find.text('Select a category'), findsOneWidget);
    expect(find.text('Amount is required'), findsOneWidget);
    expect(find.text('Description is required'), findsOneWidget);
    verifyNever(() => expenseRepository.createExpense(any()));
  });

  testWidgets('rejects a non-numeric or zero amount', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('amount_field')), 'abc');
    await tester.enterText(find.byKey(const Key('description_field')), 'Almuerzo');
    await tester.tap(find.byKey(const Key('submit_expense_button')));
    await tester.pump();

    expect(find.text('Enter a valid number'), findsOneWidget);
  });

  testWidgets('submits the expense with the correct payload', (tester) async {
    final created = Expense(
      id: 10,
      categoryId: 1,
      categoryName: 'Comida',
      amount: 12.5,
      description: 'Almuerzo',
      date: DateTime(2026, 9, 30),
    );
    when(() => expenseRepository.createExpense(any())).thenAnswer((_) async => created);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('category_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comida').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('amount_field')), '12.50');
    await tester.enterText(find.byKey(const Key('description_field')), 'Almuerzo');

    await tester.tap(find.byKey(const Key('submit_expense_button')));
    await tester.pumpAndSettle();

    final captured = verify(() => expenseRepository.createExpense(captureAny())).captured;
    expect(captured, hasLength(1));
    final submitted = captured.single as Expense;
    expect(submitted.categoryId, 1);
    expect(submitted.amount, 12.5);
    expect(submitted.description, 'Almuerzo');
    expect(submitted.id, isNull);
  });

  testWidgets('pre-fills the form and calls update + delete when editing', (tester) async {
    final existing = Expense(
      id: 7,
      categoryId: 2,
      categoryName: 'Transporte',
      amount: 20,
      description: 'Bus',
      date: DateTime(2026, 9, 20),
    );
    when(() => expenseRepository.updateExpense(7, any())).thenAnswer(
      (_) async => existing,
    );
    when(() => expenseRepository.deleteExpense(7)).thenAnswer((_) async {});

    await tester.pumpWidget(buildApp(existingExpense: existing));
    await tester.pumpAndSettle();

    expect(find.text('20.00'), findsOneWidget);
    expect(find.text('Bus'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete_expense_button')));
    await tester.pumpAndSettle();

    verify(() => expenseRepository.deleteExpense(7)).called(1);
  });
}
