import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/api_client.dart';
import 'data/auth_repository.dart';
import 'data/category_repository.dart';
import 'data/dashboard_repository.dart';
import 'data/expense_repository.dart';
import 'state/auth_state.dart';
import 'state/dashboard_state.dart';
import 'state/expenses_state.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/login_screen.dart';

void main() {
  runApp(const BudgetTrackerApp());
}

/// Root widget: wires the data layer (one shared [ApiClient] + repositories)
/// into the state layer (Provider `ChangeNotifier`s), then decides whether
/// to show the login screen or jump straight to the dashboard based on
/// whether a token is already stored.
class BudgetTrackerApp extends StatelessWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();

    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => AuthRepository(apiClient: apiClient),
        ),
        Provider<CategoryRepository>(
          create: (_) => CategoryRepository(apiClient: apiClient),
        ),
        Provider<DashboardRepository>(
          create: (_) => DashboardRepository(apiClient: apiClient),
        ),
        Provider<ExpenseRepository>(
          create: (_) => ExpenseRepository(apiClient: apiClient),
        ),
        ChangeNotifierProvider<AuthState>(
          create: (context) =>
              AuthState(authRepository: context.read<AuthRepository>())
                ..checkInitialSession(),
        ),
        ChangeNotifierProvider<DashboardState>(
          create: (context) => DashboardState(
            dashboardRepository: context.read<DashboardRepository>(),
          ),
        ),
        ChangeNotifierProvider<ExpensesState>(
          create: (context) => ExpensesState(
            expenseRepository: context.read<ExpenseRepository>(),
            categoryRepository: context.read<CategoryRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Budget Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const _AppRoot(),
      ),
    );
  }
}

/// Picks the initial screen once [AuthState.checkInitialSession] resolves.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    switch (authState.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.loggedIn:
        return const DashboardScreen();
      case AuthStatus.loggedOut:
        return const LoginScreen();
    }
  }
}
