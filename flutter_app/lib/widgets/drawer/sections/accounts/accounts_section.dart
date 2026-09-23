import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../providers/app_state.dart';
import '../../../../models/account.dart';
import '../../../../utils/helpers.dart';
import 'add_account_sheet/add_account_sheet.dart';
import 'widgets/accounts_section_ui.dart';
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

  void _showAddAccountDialog(BuildContext context, AppState state, {Account? editAccount}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF1F5F9),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: AddAccountSheet(editAccount: editAccount),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppState state, Account acc) {
    if (acc.isBank) {
      final bankCount = state.accounts.where((a) => a.isBank).length;
      if (bankCount <= 1) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFFFFFFFF),
            title: Text('삭제 불가', style: GoogleFonts.notoSansKr(color: const Color(0xFFE11D48), fontWeight: FontWeight.w700)),
            content: Text('최소 한 개의 은행 통장이 필요합니다. 카드를 연결하거나 현금 흐름을 관리하기 위해 삭제할 수 없습니다.', style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('확인', style: GoogleFonts.notoSansKr(color: const Color(0xFF4F46E5)))),
            ],
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        title: Text('계좌 삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A))),
        content: Text('${acc.name}을(를) 삭제하시겠습니까?', style: GoogleFonts.notoSansKr(color: const Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8)))),
          TextButton(
            onPressed: () { state.deleteAccount(acc.id); Navigator.pop(context); },
            child: Text('삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFFE11D48))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final banks = state.accounts.where((a) => a.isBank).toList();
        final cards = state.accounts.where((a) => !a.isBank).toList();
        
        return AccountsSectionUI(
          banks: banks,
          cards: cards,
          isExpanded: _isAccountsExpanded,
          getBankAccountBalance: (id) => state.getBankAccountBalance(id, upToDate: DateTime.now()),
          selectedAccountIds: state.selectedAccountIds,
          totalAccountsCount: state.accounts.length,
          onSelectedAccountIdsChanged: (ids) => state.setSelectedAccountIds(ids),
          onToggleExpanded: () {
            setState(() => _isAccountsExpanded = !_isAccountsExpanded);
            SharedPreferences.getInstance().then((prefs) => prefs.setBool('isAccountsExpanded', _isAccountsExpanded));
          },
          onAddClick: () => _showAddAccountDialog(context, state),
          onEditClick: (acc) => _showAddAccountDialog(context, state, editAccount: acc),
          onDeleteClick: (acc) => _showDeleteConfirmation(context, state, acc),
        );
      }
    );
  }
}
