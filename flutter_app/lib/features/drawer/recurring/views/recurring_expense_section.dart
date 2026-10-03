import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/drawer/accounts/view_models/account_view_model.dart';
import 'package:flutter_app/features/home/add_transaction/view_models/transaction_view_model.dart';
import 'package:flutter_app/features/drawer/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter_app/features/drawer/recurring/view_models/recurring_view_model.dart';
import 'package:collection/collection.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';
import 'package:flutter_app/features/drawer/recurring/views/widgets/recurring_expense_section_ui.dart';

import 'package:flutter_app/features/categories/view_models/category_view_model.dart';

class RecurringExpenseSection extends StatelessWidget {
  final DateTime drawerCashFlowDate;

  const RecurringExpenseSection({super.key, required this.drawerCashFlowDate});

  @override
  Widget build(BuildContext context) {
    return Consumer4<AccountViewModel, TransactionViewModel, RecurringViewModel, UiViewModel>(
      builder: (context, accountVM, txVM, recurringVM, uiVM, _) {
        final dashboardVM = Provider.of<DashboardViewModel>(context, listen: false);
        final dash = dashboardVM.getDashboardSummary(drawerCashFlowDate.year, drawerCashFlowDate.month);
        
        final recurringTxs = recurringVM.getNonCreditRecurringExpenses();
        final cards = recurringVM.getCreditCardsForRecurring();
        
        int totalExpense = recurringVM.getTotalRecurringExpense(drawerCashFlowDate.year, drawerCashFlowDate.month, dash);
        return RecurringExpenseSectionUI(
          isExpanded: uiVM.isRecurringExpenseExpanded,
          totalExpense: totalExpense,
          recurringTxs: recurringTxs,
          cards: cards,
          year: drawerCashFlowDate.year,
          month: drawerCashFlowDate.month,
          getAccount: (id) => accountVM.accounts.firstWhereOrNull((a) => a.id == id),
          getCardPaymentInfo: (card) => context.read<DashboardViewModel>().getCardPaymentInfo(card, drawerCashFlowDate.year, drawerCashFlowDate.month),
          getCategoryInfo: (cat) => context.read<CategoryViewModel>().getCategoryInfo(cat),
          onToggleExpanded: () {
            uiVM.toggleRecurringExpenseExpanded();
          },
          onDelete: (id) => txVM.deleteRecurringTransactions(id),
        );
      }
    );
  }
}
