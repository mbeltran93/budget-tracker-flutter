import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:budget_tracker_flutter/data/api_exception.dart';
import 'package:budget_tracker_flutter/data/auth_repository.dart';
import 'package:budget_tracker_flutter/data/category_repository.dart';
import 'package:budget_tracker_flutter/data/dashboard_repository.dart';
import 'package:budget_tracker_flutter/data/expense_repository.dart';
import 'package:budget_tracker_flutter/models/dashboard_summary.dart';
import 'package:budget_tracker_flutter/state/auth_state.dart';
import 'package:budget_tracker_flutter/state/dashboard_state.dart';
import 'package:budget_tracker_flutter/state/expenses_state.dart';
import 'package:budget_tracker_flutter/ui/screens/dashboard_screen.dart';
import 'package:budget_tracker_flutter/ui/screens/login_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDashboardRepository extends Mock implements DashboardRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockDashboardRepository dashboardRepository;
  late MockExpenseRepository expenseRepository;
  late MockCategoryRepository categoryRepository;

  setUp(() {
    authRepository = MockAuthRepository();
    dashboardRepository = MockDashboardRepository();
    expenseRepository = MockExpenseRepository();
    categoryRepository = MockCategoryRepository();

    when(() => dashboardRepository.getSummary()).thenAnswer(
      (_) async => const DashboardSummary(totalThisMonth: 0, categories: []),
    );
    when(() => expenseRepository.getExpenses()).thenAnswer((_) async => []);
    when(() => categoryRepository.getCategories()).thenAnswer((_) async => []);
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
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('shows an error message when login fails', (tester) async {
    when(() => authRepository.login(any(), any())).thenThrow(
      ApiException('Incorrect email or password.', statusCode: 401),
    );

    await tester.pumpWidget(buildApp());

    await tester.enterText(find.byKey(const Key('email_field')), 'demo@budgettracker.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'wrongpass');
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_error_text')), findsOneWidget);
    expect(find.text('Incorrect email or password.'), findsOneWidget);
    // Still on the login screen.
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('navigates to the dashboard when login succeeds', (tester) async {
    when(() => authRepository.login(any(), any())).thenAnswer((_) async => 'fake-jwt');

    await tester.pumpWidget(buildApp());

    await tester.enterText(find.byKey(const Key('email_field')), 'demo@budgettracker.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'demo1234');
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    verify(() => authRepository.login('demo@budgettracker.com', 'demo1234')).called(1);
  });

  testWidgets('shows a validation error when fields are empty', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    verifyNever(() => authRepository.login(any(), any()));
  });
}
