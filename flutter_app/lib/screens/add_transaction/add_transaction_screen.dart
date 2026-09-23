import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../models/transaction.dart';
import '../../../models/category_info.dart';
import 'widgets/add_transaction_form_ui.dart';
import 'widgets/category_dialogs.dart';

class AddTransactionScreen extends StatefulWidget {
  final String initialType;
  const AddTransactionScreen({super.key, this.initialType = 'expense'});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final GlobalKey<AddTransactionFormUiState> _formKey = GlobalKey();
  late String _initialDateStr;
  String? _initialAccountId;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _initialDateStr = s.selectedDateStr;
    if (s.accounts.isNotEmpty) _initialAccountId = s.accounts.first.id;
  }

  void _save(String type, int amount, String dateStr, String category, String accountId, String memo, bool isFixed) {
    final baseId = 'tx_${DateTime.now().millisecondsSinceEpoch}';

    if (isFixed) {
      final parts = dateStr.split('-');
      int y = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      int d = int.parse(parts[2]);
      
      List<Transaction> txs = [];
      for (int i = 0; i < 60; i++) {
        int curM = m + i;
        int curY = y + ((curM - 1) ~/ 12);
        curM = ((curM - 1) % 12) + 1;
        
        int lastDay = DateTime(curY, curM + 1, 0).day;
        int curD = d > lastDay ? lastDay : d;
        
        final loopDateStr = '$curY-${curM.toString().padLeft(2, '0')}-${curD.toString().padLeft(2, '0')}';
        
        txs.add(Transaction(
          id: '${baseId}_$i',
          date: loopDateStr, accountId: accountId, type: type,
          amount: amount, category: category, memo: memo, payment: '자동',
          isRecurring: true, recurringId: baseId,
        ));
      }
      context.read<AppState>().addTransactions(txs);
    } else {
      context.read<AppState>().addTransaction(Transaction(
        id: baseId,
        date: dateStr, accountId: accountId, type: type,
        amount: amount, category: category, memo: memo, payment: '자동',
      ));
    }
    
    Navigator.pop(context);
  }

  void _handleCategoryLongPress(CategoryInfo cat) {
    showCategoryOptionsDialog(
      context: context,
      cat: cat,
      onEdit: () {
        showCategoryEditDialog(
          context: context,
          cat: cat,
          onSave: (emoji, name) {
            final newCat = CategoryInfo(name: name, emoji: emoji, color: cat.color, type: cat.type);
            context.read<AppState>().updateCategory(newCat, cat.name);
            _formKey.currentState?.setCategory(name);
          }
        );
      },
      onDelete: () {
        final state = context.read<AppState>();
        final others = state.categories.where((c) => c.type == cat.type && c.name != cat.name).toList();
        showCategoryDeleteDialog(
          context: context,
          others: others,
          onDeleteAndTransfer: (transferToName) {
            state.deleteCategory(cat.name, transferToName);
            _formKey.currentState?.setCategory(transferToName ?? (others.isNotEmpty ? others.first.name : '기타'));
          }
        );
      }
    );
  }

  void _handleAddCategoryTap(String currentType) {
    showCategoryEditDialog(
      context: context,
      cat: null,
      onSave: (emoji, name) {
        final newCat = CategoryInfo(name: name, emoji: emoji, color: const Color(0xFF4F46E5), type: currentType);
        context.read<AppState>().addCategory(newCat);
        _formKey.currentState?.setCategory(name);
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return AddTransactionFormUi(
      key: _formKey,
      initialType: widget.initialType,
      initialDateStr: _initialDateStr,
      initialAccountId: _initialAccountId,
      categories: state.categories,
      accounts: state.accounts,
      onSave: _save,
      onAddCategoryTap: _handleAddCategoryTap,
      onCategoryLongPress: _handleCategoryLongPress,
    );
  }
}
