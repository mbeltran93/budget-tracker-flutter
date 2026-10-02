// End-to-end test against a REAL budget-tracker-spring backend.
//
// This is best-effort / optional per the project brief: it requires the
// backend actually running (via `docker compose up` in the sibling
// budget-tracker-spring repo, reachable at the configured API_BASE_URL) and
// an Android emulator or device attached. It is not run by CI and was not
// executed in the sandbox this app was built in (no emulator/device was
// available there) -- it exists for documentation/completeness, and should
// work once both prerequisites are met.
//
// Run it with (from an attached device/emulator and the backend up):
//   flutter test integration_test/app_test.dart \
//     --dart-define=API_BASE_URL=http://10.0.2.2:8080
//
// It exercises: login with the demo account -> dashboard loads -> add an
// expense -> the new expense shows up in the dashboard's recent list.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:budget_tracker_flutter/main.dart';
import 'package:budget_tracker_flutter/ui/screens/dashboard_screen.dart';
import 'package:budget_tracker_flutter/ui/screens/login_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'login -> dashboard -> add expense -> see it reflected',
    (tester) async {
      await tester.pumpWidget(const BudgetTrackerApp());
      await tester.pumpAndSettle();

      // Starts logged out (no stored token on a fresh install/test run).
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'demo@budgettracker.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'demo1234',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      // Give the real network call time to complete.
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(DashboardScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('add_expense_fab')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('category_dropdown')));
      await tester.pumpAndSettle();
      // Picks whatever category the backend returns first.
      await tester.tap(find.byType(DropdownMenuItem<int>).first, warnIfMissed: false);
      await tester.pumpAndSettle();

      const description = 'Integration test expense';
      await tester.enterText(find.byKey(const Key('amount_field')), '9.99');
      await tester.enterText(
        find.byKey(const Key('description_field')),
        description,
      );

      await tester.tap(find.byKey(const Key('submit_expense_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text(description), findsOneWidget);
    },
  );
}
