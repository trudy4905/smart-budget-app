import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/drawer/accounts/view_models/account_view_model.dart';
import 'package:flutter_app/features/drawer/accounts/models/account.dart';
import 'package:flutter_app/features/drawer/accounts/views/add_account_sheet/widgets/add_account_sheet_ui.dart';

class AddAccountSheet extends StatelessWidget {
  final Account? editAccount;
  
  const AddAccountSheet({super.key, this.editAccount});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AccountViewModel>();
    final bankAccounts = state.accounts.where((a) => a.isBank).toList();

    return AddAccountSheetUi(
      editAccount: editAccount,
      bankAccounts: bankAccounts,
      onSave: (Account acc) {
        if (editAccount != null) {
          context.read<AccountViewModel>().updateAccount(acc);
        } else {
          context.read<AccountViewModel>().addAccount(acc);
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editAccount != null ? '${acc.name}이(가) 수정되었습니다' : '${acc.name}이(가) 추가되었습니다',
              style: GoogleFonts.notoSansKr(),
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      },
    );
  }
}
