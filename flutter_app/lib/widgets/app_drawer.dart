import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_state.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../utils/helpers.dart';
import 'add_account_sheet.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isSummaryExpanded = true;
  bool _isRecurringExpanded = true;
  bool _isAccountsExpanded = true;
  bool _isAssetVisible = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSummaryExpanded = prefs.getBool('isSummaryExpanded') ?? true;
      _isRecurringExpanded = prefs.getBool('isRecurringExpanded') ?? true;
      _isAccountsExpanded = prefs.getBool('isAccountsExpanded') ?? true;
      _isAssetVisible = prefs.getBool('isAssetVisible') ?? true;
    });
  }

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
                        Text('Smart Budget',
                            style: GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
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
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text('내 자산 현황', style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isAssetVisible = !_isAssetVisible;
                                });
                                SharedPreferences.getInstance().then((prefs) => prefs.setBool('isAssetVisible', _isAssetVisible));
                              },
                              child: Icon(
                                _isAssetVisible ? Icons.visibility : Icons.visibility_off,
                                size: 16,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
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
                              Text('${state.assetReferenceDate.year.toString().substring(2)}년 ${state.assetReferenceDate.month}월 ${state.assetReferenceDate.day}일 기준', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ---- 자산 ----
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Builder(
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
                        return ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: _isAssetVisible ? 0 : 8, sigmaY: _isAssetVisible ? 0 : 8),
                          child: Text('${formatNumber(totalAssets)}원', style: GoogleFonts.notoSansKr(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF334155), letterSpacing: -0.5)),
                        );
                      }
                    ),
                  ),

                  const Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 1),

                  // ---- 월별 가계부 요약 Section Header ----
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSummaryExpanded = !_isSummaryExpanded;
                      });
                      SharedPreferences.getInstance().then((prefs) => prefs.setBool('isSummaryExpanded', _isSummaryExpanded));
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          const SizedBox(), // Removed '가계부 요약' text
                          const Spacer(),
                          if (!_isSummaryExpanded)
                            Text('${summary['income']! - summary['total']! >= 0 ? '+' : '-'}₩${formatCompactNumber((summary['income']! - summary['total']!).abs())}',
                                style: GoogleFonts.notoSansKr(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: (summary['income']! - summary['total']!) >= 0 ? const Color(0xFF059669) : const Color(0xFFE11D48))),
                          if (!_isSummaryExpanded) const SizedBox(width: 8),
                          Icon(_isSummaryExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: const Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),

                  AnimatedCrossFade(
                    firstChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---- 새로운 가계부 요약 대시보드 ----
                        Builder(
                          builder: (context) {
                            final dash = state.getDashboardSummary(state.currentDate.year, state.currentDate.month);
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Removed '{month}월 현금 흐름' header
                                // 수입
                                _dashItem(context, state, 'income', Icons.arrow_downward, const Color(0xFF059669), '수입 (들어온 돈)', null, dash.thisMonthIncome),
                                
                                // 지출
                                _dashItem(context, state, 'expense', Icons.arrow_upward, const Color(0xFFE11D48), '지출 (나간 돈)', 
                                  '(현금/체크 ${formatCompactNumber(dash.alreadyPaidCashDebit)} / 고정 ${formatCompactNumber(dash.alreadyPaidFixed)} / 카드대금 ${formatCompactNumber(dash.alreadyPaidCard)})', 
                                  dash.totalAlreadyPaid),
                                
                                // 예정
                                _dashItem(context, state, 'upcoming', Icons.schedule, const Color(0xFFF59E0B), '예정 (나갈 돈)', null, dash.totalUpcoming),
                                
                                // 예정 상세
                                if (dash.totalUpcoming > 0)
                                  Container(
                                    margin: const EdgeInsets.only(left: 44, right: 16, bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ...dash.upcomingFixedList.map((f) => _upcomingRow('고정', f.tx.memo.isNotEmpty ? '${f.tx.category}(${f.tx.memo})' : f.tx.category, '${f.dateStr} 결제', f.tx.amount)),
                                        ...dash.upcomingCardPayments.map((c) => _upcomingRow('결제 예정', c.account.name, '${c.startStr}~${c.endStr} / ${c.paymentDateStr} 결제', c.amount)),
                                        ...dash.ongoingCardAccumulations.map((c) => _upcomingRow('누적 중', c.account.name, '${c.startStr}~진행중 / ${c.paymentDateStr} 결제', c.amount)),
                                      ],
                                    ),
                                  ),

                                // 여유 자금
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Divider(color: Color(0xFFE2E8F0), height: 16),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                                  child: Row(
                                    children: [
                                      Text('(수입-(지출+예정))', style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                                      const Spacer(),
                                      Text('${dash.remaining >= 0 ? '+' : '-'}₩${formatNumber(dash.remaining.abs())}', style: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.w700, color: dash.remaining >= 0 ? const Color(0xFF059669) : const Color(0xFFE11D48))),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                        ),
                      ],
                    ),
                    secondChild: const SizedBox(width: double.infinity),
                    crossFadeState: _isSummaryExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 200),
                  ),

                  const Divider(color: Color(0xFFFFFFFF), height: 24),

                  // ---- 고정 수입/지출 ----
                  Builder(
                    builder: (context) {
                      final Map<String, Transaction> recurringMap = {};
                      for (final t in state.transactions) {
                        if (t.isRecurring && t.recurringId != null) {
                          recurringMap[t.recurringId!] = t;
                        }
                      }
                      final recurringTxs = recurringMap.values.toList();
                      final cards = state.accounts.where((a) => a.isCredit && a.paymentDay != null).toList();
                      
                      if (recurringTxs.isEmpty && cards.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() => _isRecurringExpanded = !_isRecurringExpanded);
                              SharedPreferences.getInstance().then((prefs) => prefs.setBool('isRecurringExpanded', _isRecurringExpanded));
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: Row(
                                children: [
                                  Text('고정 수입/지출', style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                                  const Spacer(),
                                  Icon(_isRecurringExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: const Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ),
                          AnimatedCrossFade(
                            firstChild: Column(
                              children: [
                                ...recurringTxs.map((tx) {
                                  final catInfo = state.getCategoryInfo(tx.category);
                                  final isExpense = tx.type == 'expense';
                                  final amountColor = isExpense ? const Color(0xFFE11D48) : const Color(0xFF059669);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFFFF),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(catInfo.emoji, style: const TextStyle(fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(tx.memo.isNotEmpty ? '${tx.category} (${tx.memo})' : tx.category, style: GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                                                Text('매달 ${int.tryParse(tx.date.split('-').last) ?? 0}일', style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF94A3B8))),
                                              ],
                                            ),
                                          ),
                                          Text('${isExpense ? '-' : '+'}₩${formatCompactNumber(tx.amount)}', style: GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.w700, color: amountColor)),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  backgroundColor: const Color(0xFFFFFFFF),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  title: Text(isExpense ? '고정 지출 삭제' : '고정 수입 삭제', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: const Color(0xFFE11D48))),
                                                  content: Text('모든 일정에서 고정 항목이 삭제됩니다.', style: GoogleFonts.notoSansKr(color: const Color(0xFF64748B))),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8)))),
                                                    TextButton(
                                                      onPressed: () {
                                                        state.deleteRecurringTransactions(tx.recurringId!);
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text('삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFFE11D48), fontWeight: FontWeight.w700)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFF94A3B8)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                ...cards.map((c) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFFFF),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Text('💳', style: TextStyle(fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('${c.name} 대금 결제', style: GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                                                Text('매달 ${c.paymentDay}일', style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF94A3B8))),
                                              ],
                                            ),
                                          ),
                                          Text('자동 계산', style: GoogleFonts.notoSansKr(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                                          const SizedBox(width: 8),
                                          const SizedBox(width: 16), // Placeholder for delete icon space
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                            secondChild: const SizedBox(width: double.infinity),
                            crossFadeState: _isRecurringExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                            duration: const Duration(milliseconds: 200),
                          ),
                          const Divider(color: Color(0xFFFFFFFF), height: 24),
                        ],
                      );
                    }
                  ),

                  // ---- 등록 계좌/카드 ----
                  GestureDetector(
                    onTap: () {
                      setState(() => _isAccountsExpanded = !_isAccountsExpanded);
                      SharedPreferences.getInstance().then((prefs) => prefs.setBool('isAccountsExpanded', _isAccountsExpanded));
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
                      child: Row(
                        children: [
                          Text('등록 계좌/카드', style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
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
                                  Text('추가', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF4F46E5))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(_isAccountsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: const Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: Column(
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
                            subLabel: acc.isCredit ? '[신용] ${acc.bank}' : acc.isDebit ? '[체크] ${acc.bank}' : '[통장] ${acc.bank}',
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
                    secondChild: const SizedBox(width: double.infinity),
                    crossFadeState: _isAccountsExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
  Widget _dashItem(BuildContext context, AppState state, String filterKey, IconData icon, Color color, String title, String? subtitle, int amount) {
    final isSelected = state.drawerFilter == filterKey;
    return GestureDetector(
      onTap: () {
        state.setDrawerFilter(isSelected ? 'none' : filterKey);
        Navigator.pop(context);
      },
      child: Container(
        color: isSelected ? color.withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.notoSansKr(fontSize: 13, color: isSelected ? color : const Color(0xFF334155), fontWeight: FontWeight.w700)),
                  if (subtitle != null)
                    Text(subtitle, style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF94A3B8))),
                ],
              ),
            ),
            Text('₩${formatNumber(amount)}', style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }

  Widget _upcomingRow(String badge, String name, String desc, int amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
            child: Text(badge, style: GoogleFonts.notoSansKr(fontSize: 9, color: const Color(0xFF475569), fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text('$name ($desc)', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
          ),
          Text('₩${formatCompactNumber(amount)}', style: GoogleFonts.notoSansKr(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFE11D48))),
        ],
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
      backgroundColor: const Color(0xFFF1F5F9),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: AddAccountSheet(editAccount: editAccount),
      ),
    );
  }
}
