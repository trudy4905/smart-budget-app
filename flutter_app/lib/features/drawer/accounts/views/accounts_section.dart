import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/drawer/dashboard/view_models/dashboard_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';
import 'package:flutter_app/features/drawer/accounts/view_models/account_view_model.dart';
import 'package:flutter_app/features/drawer/accounts/models/account.dart';
import 'package:flutter_app/features/drawer/accounts/views/add_account_sheet/add_account_sheet.dart';
import 'package:flutter_app/features/drawer/accounts/views/widgets/accounts_section_ui.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class AccountsSection extends StatefulWidget {
  const AccountsSection({super.key});

  @override
  State<AccountsSection> createState() => _AccountsSectionState();
}

class _AccountsSectionState extends State<AccountsSection> {
  bool _isAccountsExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAccountsExpanded = prefs.getBool('isAccountsExpanded') ?? true;
    });
  }

  void _showAddAccountDialog(BuildContext context, {Account? editAccount}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddAccountSheet(editAccount: editAccount),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AccountViewModel accountVM, Account acc) {
    if (acc.isBank) {
      final bankCount = accountVM.accounts.where((a) => a.isBank).length;
      if (bankCount <= 1) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('삭제 불가', style: GoogleFonts.notoSansKr(color: AppColors.expense, fontWeight: FontWeight.w700)),
            content: Text('최소 한 개의 은행 통장이 필요합니다. 카드를 연결하거나 현금 흐름을 관리하기 위해 삭제할 수 없습니다.', style: GoogleFonts.notoSansKr(color: AppColors.textMain)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('확인', style: GoogleFonts.notoSansKr(color: AppColors.primary))),
            ],
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('계좌 삭제', style: GoogleFonts.notoSansKr(color: AppColors.textMain)),
        content: Text('${acc.name}을(를) 삭제하시겠습니까?', style: GoogleFonts.notoSansKr(color: AppColors.textSub)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: GoogleFonts.notoSansKr(color: AppColors.textHint))),
          TextButton(
            onPressed: () { accountVM.deleteAccount(acc.id); Navigator.pop(context); },
            child: Text('삭제', style: GoogleFonts.notoSansKr(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountVM = context.watch<AccountViewModel>();
    final uiVM = context.watch<UiViewModel>();

    final banks = accountVM.accounts.where((a) => a.isBank).toList();
    final cards = accountVM.accounts.where((a) => !a.isBank).toList();
    
    return AccountsSectionUI(
      banks: banks,
      cards: cards,
      isExpanded: _isAccountsExpanded,
      getBankAccountBalance: (id) => context.read<DashboardViewModel>().getBankAccountBalance(id, upToDate: DateTime.now()),
      selectedAccountIds: uiVM.selectedAccountIds,
      totalAccountsCount: accountVM.accounts.length,
      onSelectedAccountIdsChanged: (ids) => uiVM.setSelectedAccountIds(ids),
      onToggleExpanded: () {
        setState(() => _isAccountsExpanded = !_isAccountsExpanded);
        SharedPreferences.getInstance().then((prefs) => prefs.setBool('isAccountsExpanded', _isAccountsExpanded));
      },
      onAddClick: () => _showAddAccountDialog(context),
      onEditClick: (acc) => _showAddAccountDialog(context, editAccount: acc),
      onDeleteClick: (acc) => _showDeleteConfirmation(context, accountVM, acc),
    );
  }
}
