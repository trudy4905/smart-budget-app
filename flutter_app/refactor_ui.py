import os
import re

def refactor_accounts_section():
    path = "lib/features/drawer/accounts/views/accounts_section.dart"
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # Replace AppState with AccountViewModel
    content = content.replace("AppState state", "AccountViewModel accountVM")
    content = content.replace("state.deleteAccount", "accountVM.deleteAccount")
    content = content.replace("state.accounts", "accountVM.accounts")
    
    # Fix _showAddAccountDialog
    content = re.sub(r'void _showAddAccountDialog\(BuildContext context, AccountViewModel accountVM, \{Account\? editAccount\}\) \{[\s\S]*?\}', 
    '''void _showAddAccountDialog(BuildContext context, {Account? editAccount}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddAccountSheet(editAccount: editAccount),
    );
  }''', content)

    # Fix build method
    content = re.sub(r'  @override\s+Widget build\(BuildContext context\) \{[\s\S]*?\}\s*\}', 
    '''  @override
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
}''', content)

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

refactor_accounts_section()
