import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/drawer/accounts/view_models/account_view_model.dart';
import 'package:flutter_app/features/home/add_transaction/view_models/transaction_view_model.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class DrawerFooterWidget extends StatelessWidget {
  const DrawerFooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () async {
            bool? confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: Text(
                  '데이터 초기화',
                  style: GoogleFonts.notoSansKr(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                content: Text(
                  '모든 계좌 및 내역 데이터가 영구적으로 삭제됩니다. 계속하시겠습니까?',
                  style: GoogleFonts.notoSansKr(color: AppColors.textSub),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('취소', style: GoogleFonts.notoSansKr(color: AppColors.textHint)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      '초기화',
                      style: GoogleFonts.notoSansKr(
                        color: const Color(0xFFEF4444),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              if (!context.mounted) return;
              context.read<AccountViewModel>().clearAccounts();
              context.read<TransactionViewModel>().clearTransactions();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFCA5A5).withOpacity(0.5),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_forever, size: 16, color: Color(0xFFEF4444)),
                const SizedBox(width: 6),
                Text(
                  '모든 데이터 초기화',
                  style: GoogleFonts.notoSansKr(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
