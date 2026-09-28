import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/core/providers/app_state.dart';
import 'package:flutter_app/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter_app/features/recurring/view_models/recurring_view_model.dart';
import 'package:collection/collection.dart';
import 'package:flutter_app/features/recurring/views/widgets/recurring_expense_section_ui.dart';

class RecurringExpenseSection extends StatefulWidget {
  final DateTime drawerCashFlowDate;

  const RecurringExpenseSection({super.key, required this.drawerCashFlowDate});

  @override
  State<RecurringExpenseSection> createState() => _RecurringExpenseSectionState();
}

class _RecurringExpenseSectionState extends State<RecurringExpenseSection> {
  bool _isRecurringExpenseExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isRecurringExpenseExpanded = prefs.getBool('isRecurringExpenseExpanded') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppState, RecurringViewModel>(
      builder: (context, state, recurringVM, _) {
        final dashboardVM = Provider.of<DashboardViewModel>(context, listen: false);
        final dash = dashboardVM.getDashboardSummary(widget.drawerCashFlowDate.year, widget.drawerCashFlowDate.month);
        
        final recurringTxs = recurringVM.getNonCreditRecurringExpenses();
        final cards = recurringVM.getCreditCardsForRecurring();
        
        int totalExpense = 0;
        for (final tx in recurringTxs) {
          final parts = tx.date.split('-');
          final regYear = parts.isNotEmpty ? int.tryParse(parts[0]) ?? widget.drawerCashFlowDate.year : widget.drawerCashFlowDate.year;
          final regMonth = parts.length >= 2 ? int.tryParse(parts[1]) ?? widget.drawerCashFlowDate.month : widget.drawerCashFlowDate.month;
          
          bool isPast = (widget.drawerCashFlowDate.year < regYear) || 
                        (widget.drawerCashFlowDate.year == regYear && widget.drawerCashFlowDate.month < regMonth);

          final acc = state.accounts.firstWhereOrNull((a) => a.id == tx.accountId);
          if (acc == null || !acc.isCredit) {
            totalExpense += isPast ? 0 : (tx.amount ?? 0);
          }
        }
        
        for (final c in cards) {
          for (final info in dash.alreadyPaidCardList) {
            if (info.account.id == c.id) totalExpense += info.amount;
          }
          for (final info in dash.upcomingCardPayments) {
            if (info.account.id == c.id) totalExpense += info.amount;
          }
        }

        return RecurringExpenseSectionUI(
          isExpanded: _isRecurringExpenseExpanded,
          totalExpense: totalExpense,
          recurringTxs: recurringTxs,
          cards: cards,
          year: widget.drawerCashFlowDate.year,
          month: widget.drawerCashFlowDate.month,
          getAccount: (id) => state.accounts.firstWhereOrNull((a) => a.id == id),
          getCardPaymentInfo: (card) => state.getCardPaymentInfo(card, widget.drawerCashFlowDate.year, widget.drawerCashFlowDate.month),
          onToggleExpanded: () {
            setState(() => _isRecurringExpenseExpanded = !_isRecurringExpenseExpanded);
            SharedPreferences.getInstance().then((prefs) => prefs.setBool('isRecurringExpenseExpanded', _isRecurringExpenseExpanded));
          },
          onDelete: (id) => state.deleteRecurringTransactions(id),
        );
      }
    );
  }
}
