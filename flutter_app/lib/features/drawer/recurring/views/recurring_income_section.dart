import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';
import 'package:flutter_app/features/home/add_transaction/view_models/transaction_view_model.dart';
import 'package:flutter_app/features/drawer/recurring/view_models/recurring_view_model.dart';
import 'package:flutter_app/features/drawer/recurring/views/widgets/recurring_income_section_ui.dart';

import 'package:flutter_app/features/categories/view_models/category_view_model.dart';

class RecurringIncomeSection extends StatelessWidget {
  final DateTime drawerCashFlowDate;

  const RecurringIncomeSection({super.key, required this.drawerCashFlowDate});

  @override
  Widget build(BuildContext context) {
    return Consumer3<UiViewModel, TransactionViewModel, RecurringViewModel>(
      builder: (context, uiVM, txVM, recurringVM, _) {
        final recurringTxs = recurringVM.getRecurringIncomes();
        final totalIncome = recurringVM.getTotalRecurringIncome();
        return RecurringIncomeSectionUI(
          isExpanded: uiVM.isRecurringIncomeExpanded,
          totalIncome: totalIncome,
          recurringTxs: recurringTxs,
          month: drawerCashFlowDate.month,
          getCategoryInfo: (cat) => context.read<CategoryViewModel>().getCategoryInfo(cat),
          onToggleExpanded: () {
            uiVM.toggleRecurringIncomeExpanded();
          },
          onDelete: (id) => txVM.deleteRecurringTransactions(id),
        );
      }
    );
  }
}
