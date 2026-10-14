import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/categories/view_models/category_view_model.dart';
import 'package:flutter_app/features/drawer/accounts/view_models/account_view_model.dart';
import 'package:flutter_app/features/home/add_transaction/view_models/transaction_view_model.dart';
import 'package:flutter_app/features/drawer/recurring/view_models/recurring_view_model.dart';
import 'package:flutter_app/features/drawer/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('SmartBudgetApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UiViewModel()),
          ChangeNotifierProvider(create: (_) => AccountViewModel()),
          ChangeNotifierProvider(create: (_) => TransactionViewModel()),
          ChangeNotifierProvider(create: (_) => CategoryViewModel()),
          ChangeNotifierProxyProvider3<AccountViewModel, TransactionViewModel, UiViewModel, RecurringViewModel>(
            create: (context) => RecurringViewModel(
              Provider.of<TransactionViewModel>(context, listen: false),
              Provider.of<AccountViewModel>(context, listen: false),
              Provider.of<UiViewModel>(context, listen: false),
            ),
            update: (context, accVM, txVM, uiVM, previous) => previous ?? RecurringViewModel(txVM, accVM, uiVM),
          ),
          ChangeNotifierProxyProvider3<AccountViewModel, TransactionViewModel, UiViewModel, DashboardViewModel>(
            create: (context) => DashboardViewModel(
              Provider.of<AccountViewModel>(context, listen: false),
              Provider.of<TransactionViewModel>(context, listen: false),
              Provider.of<UiViewModel>(context, listen: false),
            ),
            update: (context, accVM, txVM, uiVM, previous) => previous ?? DashboardViewModel(accVM, txVM, uiVM),
          ),
        ],
        child: const SmartBudgetApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(SmartBudgetApp), findsOneWidget);
  });
}
