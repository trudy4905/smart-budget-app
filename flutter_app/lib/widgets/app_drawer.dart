import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/account.dart';
import '../utils/helpers.dart';
import 'add_account_sheet.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final summary = state.getMonthlySummary(state.currentDate.year, state.currentDate.month);

        return Drawer(
          width: MediaQuery.of(context).size.width * 0.82,
          backgroundColor: const Color(0xFFF1F5F9),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Header ----
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFFFFFFF))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: Color(0xFF64748B), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Smart Budget',
                                style: GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                            Text(state.currentMonthStr,
                                style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8))),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                        ),
                      ],
                    ),
                  ),

                  // ---- 내 자산 현황 Section Header ----
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Text('내 자산 현황', style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                  ),
                  // ---- 자산 ----
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: state.assetReferenceDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              state.setAssetReferenceDate(picked);
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${state.assetReferenceDate.year.toString().substring(2)}년 ${state.assetReferenceDate.month}월 ${state.assetReferenceDate.day}일 기준 총자산', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            int totalAssets = 0;
                            final now = state.assetReferenceDate;
                            final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                            for (final acc in state.accounts) {
                              if (acc.isBank) {
                                int bal = acc.initialBalance;
                                for (final t in state.transactions) {
                                  if (t.accountId != acc.id) continue;
                                  if (t.date.compareTo(todayStr) > 0) continue;
                                  if (t.type == 'income') bal += t.amount;
                                  if (t.type == 'expense') bal -= t.amount;
                                }
                                totalAssets += bal;
                              }
                            }
                            return Text('${formatNumber(totalAssets)}원', style: GoogleFonts.notoSansKr(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF334155), letterSpacing: -0.5));
                          }
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 1),

                  // ---- 월별 가계부 요약 Section Header ----
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Row(
                      children: [
                        Text('월별 가계부 요약', style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${state.currentDate.month}월 (선택한 달)', style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF475569), fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),

                  // ---- 이번달 ----
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text('이번달 (${state.currentDate.month}월)', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                  ),
                  _drawerFilterItem(context, state, 'all', '전체', Icons.public, null, summary['income']! - summary['total']!),
                  _drawerFilterItem(context, state, 'income', '수입', Icons.attach_money, null, summary['income']!),
                  Builder(
                    builder: (context) {
                      String cashSub = [
                        if (summary['bankExpense']! > 0) '현금 ${formatCompactNumber(summary['bankExpense']!)}',
                        if (summary['debitExpense']! > 0) '체크 ${formatCompactNumber(summary['debitExpense']!)}',
                        if (summary['lastMonthCardBill']! > 0) '지난달 카드 ${formatCompactNumber(summary['lastMonthCardBill']!)}',
                      ].join(' / ');
                      return _drawerFilterItem(
                        context, state, 'cash', '지출', Icons.money,
                        cashSub.isEmpty ? null : '($cashSub)',
                        summary['cash']!
                      );
                    }
                  ),

                  // ---- 다음달 ----
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('다음달 (${state.currentDate.month + 1 > 12 ? 1 : state.currentDate.month + 1}월)', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                  ),
                  _drawerFilterItem(context, state, 'next_all', '전체', Icons.public, null, -summary['card']!),
                  _drawerFilterItem(context, state, 'next_income', '수입', Icons.attach_money, null, 0),
                  _drawerFilterItem(context, state, 'next_card', '지출', Icons.credit_card, '(고정 지출/이번달 카드)', summary['card']!),

                  const Divider(color: Color(0xFFFFFFFF), height: 24),

                  // ---- 등록 계좌/카드 ----
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Text('등록 계좌/카드', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            _showAddAccountDialog(context, state);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add, size: 12, color: Color(0xFF4F46E5)),
                                const SizedBox(width: 4),
                                Text('계좌/카드 추가', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF4F46E5))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      ...state.accounts.map((acc) {
                        int? amount;
                        if (acc.isBank) {
                          int bal = acc.initialBalance;
                          final now = DateTime.now();
                          final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                          for (final t in state.transactions) {
                            if (t.accountId != acc.id) continue;
                            if (t.date.compareTo(todayStr) > 0) continue;
                            if (t.type == 'income') bal += t.amount;
                            if (t.type == 'expense') bal -= t.amount;
                          }
                          amount = bal;
                        } else if (acc.isCredit) {
                          amount = -state.getCardBillForMonth(acc.id, state.currentDate.year, state.currentDate.month);
                        }
                        return _accountCheckItem(
                          context, state,
                          id: acc.id,
                          icon: acc.isCredit ? Icons.credit_card : acc.isDebit ? Icons.credit_card : Icons.account_balance,
                          label: acc.name,
                          subLabel: acc.isCredit ? '[신용]' : acc.isDebit ? '[체크]' : '[통장] ${acc.bank}',
                          color: hexToColor(acc.color),
                          amount: amount,
                          isAll: false,
                          onAction: (action) {
                            if (action == 'edit') {
                              _showAddAccountDialog(context, state, editAccount: acc);
                            } else if (action == 'delete') {
                              _showDeleteConfirmation(context, state, acc);
                            }
                          },
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

  }

  Widget _drawerFilterItem(BuildContext context, AppState state, String filter, String label, IconData icon, String? sub, int amount) {
    final isActive = state.drawerFilter == filter;
    final isPositive = amount >= 0;
    final isIncomeFilter = filter == 'income' || filter == 'next_income';
    final isAllFilter = filter == 'all' || filter == 'next_all';
    final amountColor = isIncomeFilter
        ? const Color(0xFF059669)
        : isAllFilter
            ? (isPositive ? const Color(0xFF059669) : const Color(0xFFE11D48))
            : const Color(0xFFE11D48);
    final amountStr = isIncomeFilter || isAllFilter
        ? (isPositive ? '+₩${formatCompactNumber(amount)}' : '-₩${formatCompactNumber(amount.abs())}')
        : '-₩${formatCompactNumber(amount)}';

    return GestureDetector(
      onTap: () {
        state.setDrawerFilter(filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: const Color(0xFF4F46E5).withOpacity(0.4)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                      )),
                  if (sub != null)
                    Text(sub, style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF94A3B8))),
                ],
              ),
            ),
            Text(amountStr,
                style: GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.w700, color: amountColor)),
            if (isActive) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_rounded, size: 14, color: Color(0xFF4F46E5)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _accountCheckItem(
    BuildContext context,
    AppState state, {
    required String id,
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
    required int? amount,
    required bool isAll,
    Function(String)? onAction,
  }) {
    final isAllActive = state.selectedAccountIds.contains('all');
    final isChecked = isAll ? isAllActive : (isAllActive || state.selectedAccountIds.contains(id));

    return GestureDetector(
      onTap: () {
        if (isAll) {
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
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isChecked ? color.withOpacity(0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: isChecked ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isChecked ? color : const Color(0xFFE2E8F0), width: 2),
              ),
              child: isChecked ? const Icon(Icons.check, size: 12, color: Color(0xFF0F172A)) : null,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        color: isChecked ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                      )),
                  Text(subLabel, style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF94A3B8))),
                ],
              ),
            ),
            if (amount != null)
              Text(
                amount >= 0 ? '₩${formatNumber(amount)}' : '-₩${formatNumber(amount.abs())}',
                style: GoogleFonts.notoSansKr(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: amount >= 0 ? const Color(0xFF059669) : const Color(0xFFE11D48),
                ),
              ),
            if (onAction != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: Color(0xFF94A3B8)),
                color: const Color(0xFFFFFFFF),
                onSelected: onAction,
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'edit', child: Text('수정', style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFF0F172A)))),
                  PopupMenuItem(value: 'delete', child: Text('삭제', style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFFE11D48)))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppState state, Account acc) {
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

  void _showAddAccountDialog(BuildContext context, AppState state, {Account? editAccount}) {
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
  }
}
