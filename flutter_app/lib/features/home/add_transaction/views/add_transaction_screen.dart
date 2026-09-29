import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/home/add_transaction/view_models/transaction_view_model.dart';
import 'package:flutter_app/features/drawer/accounts/view_models/account_view_model.dart';
import 'package:flutter_app/features/categories/view_models/category_view_model.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';
import 'package:flutter_app/features/home/add_transaction/models/transaction.dart';
import 'package:flutter_app/features/categories/models/category_info.dart';
import 'package:flutter_app/features/home/add_transaction/views/widgets/add_transaction_form_ui.dart';
import 'package:flutter_app/features/home/add_transaction/views/widgets/category_dialogs.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

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
    final uiVM = context.read<UiViewModel>();
    final accountVM = context.read<AccountViewModel>();
    _initialDateStr = uiVM.selectedDateStr;
    if (accountVM.accounts.isNotEmpty) _initialAccountId = accountVM.accounts.first.id;
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
      context.read<TransactionViewModel>().addTransactions(txs);
    } else {
      context.read<TransactionViewModel>().addTransaction(Transaction(
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
            context.read<CategoryViewModel>().updateCategory(newCat, cat.name);
            _formKey.currentState?.setCategory(name);
          }
        );
      },
      onDelete: () {
        final catVM = context.read<CategoryViewModel>();
        final txVM = context.read<TransactionViewModel>();
        final others = catVM.categories.where((c) => c.type == cat.type && c.name != cat.name).toList();
        showCategoryDeleteDialog(
          context: context,
          others: others,
          onDeleteAndTransfer: (transferToName) {
            if (transferToName != null) {
              txVM.transferCategory(cat.name, transferToName);
            }
            catVM.deleteCategory(cat.name);
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
        final newCat = CategoryInfo(name: name, emoji: emoji, color: AppColors.primary, type: currentType);
        context.read<CategoryViewModel>().addCategory(newCat);
        _formKey.currentState?.setCategory(name);
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final catVM = context.watch<CategoryViewModel>();
    final accountVM = context.watch<AccountViewModel>();

    return AddTransactionFormUi(
      key: _formKey,
      initialType: widget.initialType,
      initialDateStr: _initialDateStr,
      initialAccountId: _initialAccountId,
      categories: catVM.categories,
      accounts: accountVM.accounts,
      onSave: _save,
      onAddCategoryTap: _handleAddCategoryTap,
      onCategoryLongPress: _handleCategoryLongPress,
    );
  }
}
