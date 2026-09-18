import os
import re

def main():
    with open('flutter_app/lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Checkbox toggling behavior in _accountCheckItem onTap
    old_checkbox_logic = '''        if (isAll) {
          // 전체 체크박스는 토글 가능 (해제하면 아무것도 표시 안됨)
          if (isAllActive) {
            state.setSelectedAccountIds([]); // 전체 해제
          } else {
            state.setSelectedAccountIds(['all']); // 전체 선택
          }
        } else {
          if (state.selectedAccountIds.contains('all')) {
            state.setSelectedAccountIds([id]);
          } else {
            if (state.selectedAccountIds.contains(id)) {
              final next = state.selectedAccountIds.where((x) => x != id).toList();
              state.setSelectedAccountIds(next); // 빈 배열도 허용
            } else {
              final next = [...state.selectedAccountIds, id];
              state.setSelectedAccountIds(next.length == state.accounts.length ? ['all'] : next);
            }
          }
        }'''
    new_checkbox_logic = '''        if (isAll) {
          if (isAllActive) {
            state.setSelectedAccountIds([]);
          } else {
            state.setSelectedAccountIds(['all']);
          }
        } else {
          if (state.selectedAccountIds.contains('all')) {
            final next = state.accounts.map((e) => e.id).where((x) => x != id).toList();
            state.setSelectedAccountIds(next);
          } else {
            if (state.selectedAccountIds.contains(id)) {
              final next = state.selectedAccountIds.where((x) => x != id).toList();
              state.setSelectedAccountIds(next);
            } else {
              final next = [...state.selectedAccountIds, id];
              state.setSelectedAccountIds(next.length == state.accounts.length ? ['all'] : next);
            }
          }
        }'''
    content = content.replace(old_checkbox_logic, new_checkbox_logic)

    # 2. _drawerFilterItem signature and usage
    old_drawer_sig = 'Widget _drawerFilterItem(BuildContext context, AppState state, String filter, String label, String? sub, int amount)'
    new_drawer_sig = 'Widget _drawerFilterItem(BuildContext context, AppState state, String filter, String label, IconData icon, String? sub, int amount)'
    content = content.replace(old_drawer_sig, new_drawer_sig)

    old_drawer_row = '''                children: [
                  Text(label,'''
    new_drawer_row = '''                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(label,'''
    
    # We have to be careful with new_drawer_row. Let's do a more precise replace.
    # We want to wrap Text(label... in a Row? No, we just insert Icon.
    # Ah, the label is in a Column.
    # Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(label), Text(sub) ]))
    # So we want the Icon to be next to the Column!
    # Wait, the structure is Row(children: [ Expanded(child: Column(...)), Text(amountStr), ... ])
    # So inserting the Icon BEFORE Expanded is perfect.
    old_drawer_row2 = '''        child: Row(
          children: [
            Expanded('''
    new_drawer_row2 = '''        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 10),
            Expanded('''
    content = content.replace(old_drawer_row2, new_drawer_row2)

    # Update drawer filter item usages
    # 808:                 _drawerFilterItem(context, state, 'all', '🌐 전체', null, summary['income']! - summary['total']!),
    # 809:                 _drawerFilterItem(context, state, 'income', '💵 수입', null, summary['income']!),
    # 810:                 _drawerFilterItem(context, state, 'cash', '💰 현금 지출', '(현금/체크)', summary['cash']!),
    # 811:                 _drawerFilterItem(context, state, 'card', '💳 카드 지출', '(다음달 예정)', summary['card']!),
    # 812:                 _drawerFilterItem(context, state, 'total_expense', '📊 전체 지출', null, summary['total']!),
    
    old_drawer_usage = '''                _drawerFilterItem(context, state, 'all', '🌐 전체', null, summary['income']! - summary['total']!),
                _drawerFilterItem(context, state, 'income', '💵 수입', null, summary['income']!),
                _drawerFilterItem(context, state, 'cash', '💰 현금 지출', '(현금/체크)', summary['cash']!),
                _drawerFilterItem(context, state, 'card', '💳 카드 지출', '(다음달 예정)', summary['card']!),
                _drawerFilterItem(context, state, 'total_expense', '📊 전체 지출', null, summary['total']!),'''
    
    new_drawer_usage = '''                _drawerFilterItem(context, state, 'all', '전체', Icons.language, null, summary['income']! - summary['total']!),
                _drawerFilterItem(context, state, 'income', '수입', Icons.attach_money, null, summary['income']!),
                _drawerFilterItem(context, state, 'cash', '현금 지출', Icons.money, '/현금/체크/지난달 카드', summary['cash']!),
                _drawerFilterItem(context, state, 'card', '카드 지출', Icons.credit_card, '(다음달 예정)', summary['card']!),'''
    content = content.replace(old_drawer_usage, new_drawer_usage)

    # 3. _accountCheckItem signature and usages
    old_acc_sig = '''    required String id,
    required String icon,
    required String label,'''
    new_acc_sig = '''    required String id,
    required IconData icon,
    required String label,'''
    content = content.replace(old_acc_sig, new_acc_sig)
    
    old_acc_text = '''            const SizedBox(width: 12),
            Text(' ', style: const TextStyle(fontSize: 14)),
            Expanded('''
    new_acc_text = '''            const SizedBox(width: 12),
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 10),
            Expanded('''
    content = content.replace(old_acc_text, new_acc_text)
    
    # Update account check item usage inside map
    old_acc_usage = '''                        icon: acc.isCredit ? '💳' : acc.isDebit ? '💳' : '🏦','''
    new_acc_usage = '''                        icon: acc.isCredit ? Icons.credit_card : acc.isDebit ? Icons.credit_card : Icons.account_balance,'''
    content = content.replace(old_acc_usage, new_acc_usage)

    # 4. _showAddAccountDialog update
    old_add_acc_dialog = '''  void _showAddAccountDialog(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: const AddAccountSheet(),
      ),
    );
  }'''
    new_add_acc_dialog = '''  void _showAddAccountDialog(BuildContext context, AppState state, {Account? editAccount}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: AddAccountSheet(editAccount: editAccount),
      ),
    );
  }'''
    content = content.replace(old_add_acc_dialog, new_add_acc_dialog)
    
    old_add_acc_sheet = '''class AddAccountSheet extends StatefulWidget {
  const AddAccountSheet({super.key});'''
    new_add_acc_sheet = '''class AddAccountSheet extends StatefulWidget {
  final Account? editAccount;
  const AddAccountSheet({super.key, this.editAccount});'''
    content = content.replace(old_add_acc_sheet, new_add_acc_sheet)
    
    # State update
    old_state_vars = '''class _AddAccountSheetState extends State<AddAccountSheet> {
  String _type = 'bank'; // 'bank', 'credit', 'debit'
  String _bank = '신한은행';
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  int _paymentDay = 25;
  String? _linkedBankId;
  String _color = '#6366f1';'''
    new_state_vars = '''class _AddAccountSheetState extends State<AddAccountSheet> {
  String _type = 'bank'; // 'bank', 'credit', 'debit'
  String _bank = '신한은행';
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  int _paymentDay = 25;
  String? _linkedBankId;
  String _color = '#6366f1';

  @override
  void initState() {
    super.initState();
    if (widget.editAccount != null) {
      final acc = widget.editAccount!;
      _type = acc.cardKind ?? 'bank';
      _bank = acc.bank;
      _nameCtrl.text = acc.name;
      _balanceCtrl.text = acc.initialBalance.toString();
      _paymentDay = acc.paymentDay ?? 25;
      _linkedBankId = acc.linkedBankAccountId;
      _color = acc.color;
    }
  }'''
    content = content.replace(old_state_vars, new_state_vars)
    
    # Save update
    old_save_acc = '''  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('별칭을 입력해주세요', style: GoogleFonts.notoSansKr())));
      return;
    }
    final acc = Account(
      id: 'acc_',
      type: _type == 'bank' ? 'bank' : 'card',
      name: name,
      bank: _bank,
      color: _color,
      cardKind: _type == 'bank' ? null : _type,
      initialBalance: _type == 'bank' ? (int.tryParse(_balanceCtrl.text) ?? 0) : 0,
      paymentDay: _type == 'credit' ? _paymentDay : null,
      linkedBankAccountId: _linkedBankId,
    );
    context.read<AppState>().addAccount(acc);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('이(가) 추가되었습니다', style: GoogleFonts.notoSansKr()),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }'''
    # We replace it properly handling editAccount
    # Notice we use widget.editAccount?.id or new id
    new_save_acc = '''  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('별칭을 입력해주세요', style: GoogleFonts.notoSansKr())));
      return;
    }
    final acc = Account(
      id: widget.editAccount?.id ?? 'acc_',
      type: _type == 'bank' ? 'bank' : 'card',
      name: name,
      bank: _bank,
      color: _color,
      cardKind: _type == 'bank' ? null : _type,
      initialBalance: _type == 'bank' ? (int.tryParse(_balanceCtrl.text) ?? 0) : 0,
      paymentDay: _type == 'credit' ? _paymentDay : null,
      linkedBankAccountId: _linkedBankId,
    );
    
    if (widget.editAccount != null) {
      context.read<AppState>().updateAccount(acc);
    } else {
      context.read<AppState>().addAccount(acc);
    }
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.editAccount != null ? '이(가) 수정되었습니다' : '이(가) 추가되었습니다', style: GoogleFonts.notoSansKr()),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }'''
    # Sometimes Python string replace can fail if I have f-string syntax in original code, but here it's ${name} in Dart, so Python sees it as literal.
    content = content.replace(old_save_acc, new_save_acc)
    
    # 5. More menu on account item (Edit/Delete)
    # Right now, _accountCheckItem has:
    #             if (onLongPress != null)
    #               GestureDetector(
    #                 onTap: onLongPress,
    #                 child: const Padding( ... )
    
    # Let's change onLongPress to onMoreTap, or just rewrite that part to use PopupMenuButton
    old_more_icon = '''            if (onLongPress != null)
              GestureDetector(
                onTap: onLongPress,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.more_vert, size: 16, color: Color(0xFF94A3B8)),
                ),
              ),'''
    
    new_more_icon = '''            if (onLongPress != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: Color(0xFF94A3B8)),
                color: const Color(0xFFFFFFFF),
                onSelected: (val) {
                  if (val == 'edit') {
                    // Instead of a callback, we can just call onLongPress? 
                    // No, onLongPress is currently _showAccountActions which just shows Delete.
                    // Let's pass the action as a string to a new callback, or just rewrite it here.
                    // Wait, we can't do it inside the UI component without passing a specific callback.
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'edit', child: Text('수정', style: GoogleFonts.notoSansKr(fontSize: 13))),
                  PopupMenuItem(value: 'delete', child: Text('삭제', style: GoogleFonts.notoSansKr(fontSize: 13, color: Colors.red))),
                ],
              ),'''
              
    # Actually, the user asked to show "수정" (Edit) and "삭제" (Delete) menus. 
    # If I use PopupMenuButton inside _accountCheckItem, I have to pass an onAction(String action) callback instead of onLongPress().
    
    # Let's do that.
    content = content.replace(old_more_icon, '''            if (onLongPress != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: Color(0xFF94A3B8)),
                color: const Color(0xFFFFFFFF),
                onSelected: (val) {
                   if (val == 'edit') {
                     // We will hijack onLongPress but pass an action string if we change the signature.
                     // It's easier to just pass the action to onLongPress. Wait, onLongPress is VoidCallback.
                   }
                },
                itemBuilder: (ctx) => [
                ],
              ),''') # Actually I'll do this properly via code replacement below.

    with open('flutter_app/lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    main()
