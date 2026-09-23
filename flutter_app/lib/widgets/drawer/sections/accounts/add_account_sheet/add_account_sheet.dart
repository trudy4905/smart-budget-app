import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../../providers/app_state.dart';
import '../../../../../models/account.dart';
import 'widgets/add_account_sheet_ui.dart';

class AddAccountSheet extends StatelessWidget {
  final Account? editAccount;
  
  const AddAccountSheet({super.key, this.editAccount});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bankAccounts = state.accounts.where((a) => a.isBank).toList();

    return AddAccountSheetUi(
      editAccount: editAccount,
      bankAccounts: bankAccounts,
      onSave: (Account acc) {
        if (editAccount != null) {
          context.read<AppState>().updateAccount(acc);
        } else {
          context.read<AppState>().addAccount(acc);
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
