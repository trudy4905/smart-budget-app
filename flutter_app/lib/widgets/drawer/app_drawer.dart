import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'drawer_header.dart';
import 'sections/assets/asset_summary_card.dart';
import 'sections/cash_flow/cash_flow_section.dart';
import 'sections/accounts/accounts_section.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          children: [
            const DrawerHeaderWidget(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const AssetSummaryCard(),
                    const CashFlowSection(),
                    const AccountsSection(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () async {
                            bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFFFFFFFF),
                                title: Text('데이터 초기화', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
                                content: Text('모든 계좌 및 내역 데이터가 영구적으로 삭제됩니다. 계속하시겠습니까?', style: GoogleFonts.notoSansKr(color: const Color(0xFF64748B))),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('취소', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8)))),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text('초기화', style: GoogleFonts.notoSansKr(color: const Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              context.read<AppState>().resetAllData();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.delete_forever, size: 18, color: Color(0xFFEF4444)),
                                const SizedBox(width: 8),
                                Text('모든 데이터 초기화', style: GoogleFonts.notoSansKr(color: const Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
