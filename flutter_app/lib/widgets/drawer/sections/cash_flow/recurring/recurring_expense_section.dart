import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../providers/app_state.dart';
import 'package:collection/collection.dart';
import '../../../../../models/transaction.dart';
import 'widgets/recurring_expense_section_ui.dart';

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
    return Consumer<AppState>(
      builder: (context, state, _) {
        final dash = state.getDashboardSummary(widget.drawerCashFlowDate.year, widget.drawerCashFlowDate.month);
        
        final Map<String, Transaction> recurringMap = {};
        for (final t in state.transactions) {
          if (t.isRecurring && t.recurringId != null && t.type == 'expense') {
            if (!state.selectedAccountIds.contains('all') && !state.selectedAccountIds.contains(t.accountId)) continue;
            recurringMap[t.recurringId!] = t;
          }
        }
        final recurringTxs = recurringMap.values.toList();
        final cards = state.accounts.where((a) => a.isCredit && a.paymentDay != null && (state.selectedAccountIds.contains('all') || state.selectedAccountIds.contains(a.id))).toList();
        
        int totalExpense = 0;
        for (final tx in recurringTxs) {
          final acc = state.accounts.firstWhereOrNull((a) => a.id == tx.accountId);
          if (acc == null || !acc.isCredit) {
            totalExpense += (tx.amount ?? 0);
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
