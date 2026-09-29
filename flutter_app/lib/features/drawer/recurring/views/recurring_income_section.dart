import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/core/providers/app_state.dart';
import 'package:flutter_app/features/home/add_transaction/models/transaction.dart';
import 'package:flutter_app/features/drawer/recurring/views/widgets/recurring_income_section_ui.dart';

class RecurringIncomeSection extends StatefulWidget {
  final DateTime drawerCashFlowDate;

  const RecurringIncomeSection({super.key, required this.drawerCashFlowDate});

  @override
  State<RecurringIncomeSection> createState() => _RecurringIncomeSectionState();
}

class _RecurringIncomeSectionState extends State<RecurringIncomeSection> {
  bool _isRecurringIncomeExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isRecurringIncomeExpanded = prefs.getBool('isRecurringIncomeExpanded') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final Map<String, Transaction> recurringMap = {};
        for (final t in state.transactions) {
          if (t.isRecurring && t.recurringId != null && t.type == 'income') {
            if (!state.selectedAccountIds.contains('all') && !state.selectedAccountIds.contains(t.accountId)) continue;
            recurringMap[t.recurringId!] = t;
          }
        }
        final recurringTxs = recurringMap.values.toList();
        
        int totalIncome = recurringTxs.fold(0, (sum, tx) => sum + tx.amount);

        return RecurringIncomeSectionUI(
          isExpanded: _isRecurringIncomeExpanded,
          totalIncome: totalIncome,
          recurringTxs: recurringTxs,
          month: widget.drawerCashFlowDate.month,
          onToggleExpanded: () {
            setState(() => _isRecurringIncomeExpanded = !_isRecurringIncomeExpanded);
            SharedPreferences.getInstance().then((prefs) => prefs.setBool('isRecurringIncomeExpanded', _isRecurringIncomeExpanded));
          },
          onDelete: (id) => state.deleteRecurringTransactions(id),
        );
      }
    );
  }
}

