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
  bool _isAssetVisible = true;
  bool _isRecurringExpenseExpanded = true;
  bool _isRecurringIncomeExpanded = true;
  bool _isAccountsExpanded = true;
  
  bool _isIncomeExpanded = false;
  bool _isExpenseExpanded = false;
  bool _isUpcomingIncomeExpanded = false;
  bool _isUpcomingExpenseExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAssetVisible = prefs.getBool('isAssetVisible') ?? true;
      _isRecurringExpenseExpanded = prefs.getBool('isRecurringExpenseExpanded') ?? true;
      _isRecurringIncomeExpanded = prefs.getBool('isRecurringIncomeExpanded') ?? true;
      _isAccountsExpanded = prefs.getBool('isAccountsExpanded') ?? true;
      
      _isIncomeExpanded = prefs.getBool('isIncomeExpanded') ?? false;
      _isExpenseExpanded = prefs.getBool('isExpenseExpanded') ?? false;
      _isUpcomingIncomeExpanded = prefs.getBool('isUpcomingIncomeExpanded') ?? false;
      _isUpcomingExpenseExpanded = prefs.getBool('isUpcomingExpenseExpanded') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final dash = state.getDashboardSummary(state.currentDate.year, state.currentDate.month);

        return Drawer(
          width: MediaQuery.of(context).size.width * 0.85,
          backgroundColor: const Color(0xFFF9FAFB),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Header ----
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: Color(0xFFFFFFFF), size: 16),
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

                  // ---- 내 자산 현황 ----
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('내 자산 현황', style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _isAssetVisible = !_isAssetVisible);
                                    SharedPreferences.getInstance().then((prefs) => prefs.setBool('isAssetVisible', _isAssetVisible));
                                  },
                                  child: Icon(_isAssetVisible ? Icons.visibility : Icons.visibility_off, size: 16, color: const Color(0xFF94A3B8)),
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
                                children: [
                                  Text('${state.assetReferenceDate.year.toString().substring(2)}년 ${state.assetReferenceDate.month}월 ${state.assetReferenceDate.day}일 기준', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                            return ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: _isAssetVisible ? 0 : 8, sigmaY: _isAssetVisible ? 0 : 8),
                              child: Text('${formatNumber(totalAssets)}원', style: GoogleFonts.notoSansKr(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), letterSpacing: -0.5)),
                            );
                          }
                        ),
                      ],
                    ),
                  ),

                  // ---- 9월 현금 흐름 Card ----
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${state.currentDate.month}월 현금 흐름', style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                          const SizedBox(height: 16),
                          _cashFlowRow(context, state, 'income', Icons.arrow_downward, const Color(0xFF059669), const Color(0xFFECFDF5), '수입', dash.totalAlreadyReceived, 
                            _isIncomeExpanded, 
                            () {
                              setState(() => _isIncomeExpanded = !_isIncomeExpanded);
                              SharedPreferences.getInstance().then((prefs) => prefs.setBool('isIncomeExpanded', _isIncomeExpanded));
                            },
                            dash.alreadyReceivedIncomeList.map((tx) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text('${tx.date.substring(5).replaceAll('-', '/')} ${tx.memo.isNotEmpty ? '${tx.category} (${tx.memo})' : tx.category}', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF475569)), overflow: TextOverflow.ellipsis)),
                                Text('${formatNumber(tx.amount)}원', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF475569))),
                              ]
                            )).toList(),
                          ),
                          const SizedBox(height: 12),
                          _cashFlowRow(context, state, 'expense', Icons.arrow_upward, const Color(0xFFE11D48), const Color(0xFFFFF1F2), '지출', dash.totalAlreadyPaid,
                            _isExpenseExpanded, 
                            () {
                              setState(() => _isExpenseExpanded = !_isExpenseExpanded);
                              SharedPreferences.getInstance().then((prefs) => prefs.setBool('isExpenseExpanded', _isExpenseExpanded));
                            },
                            [
                              ...dash.alreadyPaidFixedList.map((tx) => Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('${tx.date.substring(5).replaceAll('-', '/')} ${tx.memo.isNotEmpty ? '${tx.category} (${tx.memo})' : tx.category}', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF475569)), overflow: TextOverflow.ellipsis)),
                                  Text('${formatNumber(tx.amount)}원', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF475569))),
                                ]
                              )),
                              ...dash.alreadyPaidCashDebitList.map((tx) => Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('${tx.date.substring(5).replaceAll('-', '/')} ${tx.memo.isNotEmpty ? '${tx.category} (${tx.memo})' : tx.category}', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF475569)), overflow: TextOverflow.ellipsis)),
                                  Text('${formatNumber(tx.amount)}원', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF475569))),
                                ]
                              )),
                              ...dash.alreadyPaidCardList.map((c) => Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('${c.paymentDateStr} ${c.account.name} 대금', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF475569)), overflow: TextOverflow.ellipsis)),
                                  Text('${formatNumber(c.amount)}원', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF475569))),
                                ]
                              )),
                            ]
                          ),
                          const SizedBox(height: 12),
                          _cashFlowRow(context, state, 'upcoming_income', Icons.schedule, const Color(0xFFD97706), const Color(0xFFFEF3C7), '예정수입', dash.totalUpcomingIncome,
                            _isUpcomingIncomeExpanded, 
                            () {
                              setState(() => _isUpcomingIncomeExpanded = !_isUpcomingIncomeExpanded);
                              SharedPreferences.getInstance().then((prefs) => prefs.setBool('isUpcomingIncomeExpanded', _isUpcomingIncomeExpanded));
                            },
                            dash.upcomingIncomeList.map((e) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text('${e.dateStr.replaceAll('.', '/')} ${e.tx.memo.isNotEmpty ? '${e.tx.category} (${e.tx.memo})' : e.tx.category}', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF475569)), overflow: TextOverflow.ellipsis)),
                                Text('${formatNumber(e.tx.amount)}원', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF475569))),
                              ]
                            )).toList(),
                          ),
                          const SizedBox(height: 12),
                          _cashFlowRow(context, state, 'upcoming_expense', Icons.calendar_today, const Color(0xFF7C3AED), const Color(0xFFF3E8FF), '예정지출', dash.totalUpcomingExpense,
                            _isUpcomingExpenseExpanded, 
                            () {
                              setState(() => _isUpcomingExpenseExpanded = !_isUpcomingExpenseExpanded);
                              SharedPreferences.getInstance().then((prefs) => prefs.setBool('isUpcomingExpenseExpanded', _isUpcomingExpenseExpanded));
                            },
                            [
                              ...dash.upcomingExpenseList.map((e) => Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('${e.dateStr.replaceAll('.', '/')} ${e.tx.memo.isNotEmpty ? '${e.tx.category} (${e.tx.memo})' : e.tx.category}', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF475569)), overflow: TextOverflow.ellipsis)),
                                  Text('${formatNumber(e.tx.amount)}원', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF475569))),
                                ]
                              )),
                              ...dash.upcomingCardPayments.map((c) => Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('${c.paymentDateStr.replaceAll('.', '/')} ${c.account.name}', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF475569)), overflow: TextOverflow.ellipsis)),
                                  Text('${formatNumber(c.amount)}원', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF475569))),
                                ]
                              )),
                            ]
                          ),
                          const SizedBox(height: 16),
                          // 이번 달 예상 잔액
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.monetization_on_outlined, color: Color(0xFF059669), size: 20),
                                const SizedBox(width: 8),
                                Text('이번 달 예상 잔액', style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFF065F46), fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Text('${dash.remaining >= 0 ? '+' : ''}${formatNumber(dash.remaining)}원', style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ---- 이번 달 고정 내역 (지출) ----
                  Builder(
                    builder: (context) {
                      final Map<String, Transaction> recurringMap = {};
                      for (final t in state.transactions) {
                        if (t.isRecurring && t.recurringId != null && t.type == 'expense') {
                          recurringMap[t.recurringId!] = t;
                        }
                      }
                      final recurringTxs = recurringMap.values.toList();
                      final cards = state.accounts.where((a) => a.isCredit && a.paymentDay != null).toList();
                      
                      if (recurringTxs.isEmpty && cards.isEmpty) return const SizedBox.shrink();

                      int totalExpense = recurringTxs.fold(0, (sum, tx) => sum + (tx.amount ?? 0));
                      for (final c in cards) {
                        for (final info in dash.alreadyPaidCardList) {
                          if (info.account.id == c.id) totalExpense += info.amount;
                        }
                        for (final info in dash.upcomingCardPayments) {
                          if (info.account.id == c.id) totalExpense += info.amount;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() => _isRecurringExpenseExpanded = !_isRecurringExpenseExpanded);
                                  SharedPreferences.getInstance().then((prefs) => prefs.setBool('isRecurringExpenseExpanded', _isRecurringExpenseExpanded));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                                  child: Row(
                                    children: [
                                      Text('이번 달 고정 지출', style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                                      const Spacer(),
                                      Text(formatNumber(totalExpense), style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFFE11D48), fontWeight: FontWeight.w700)),
                                      const SizedBox(width: 8),
                                      Icon(_isRecurringExpenseExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 16, color: const Color(0xFF94A3B8)),
                                    ],
                                  ),
                                ),
                              ),
                              AnimatedCrossFade(
                                firstChild: Column(
                                  children: [
                                    ...recurringTxs.map((tx) {
                                      return _recurringItem(
                                        context, state,
                                        iconBgColor: const Color(0xFFFFF1F2),
                                        iconColor: const Color(0xFFE11D48),
                                        title: tx.memo.isNotEmpty ? '${tx.category} (${tx.memo})' : tx.category,
                                        subtitle: '${state.currentDate.month}/${int.tryParse(tx.date.split('-').last) ?? 0}',
                                        amount: tx.amount,
                                        onDelete: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              backgroundColor: const Color(0xFFFFFFFF),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              title: Text('고정 지출 삭제', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: const Color(0xFFE11D48))),
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
                                      );
                                    }),
                                    ...cards.map((c) {
                                      final cardInfo = state.getCardPaymentInfo(c, state.currentDate.year, state.currentDate.month);
                                      int cardPaymentAmount = cardInfo.amount;
                                      
                                      String subtitle = '${cardInfo.startStr.replaceAll('.', '/')}~${cardInfo.endStr.replaceAll('.', '/')} | ${cardInfo.paymentDateStr.replaceAll('.', '/')}';
                                      Widget titleTag;
                                      if (cardInfo.isFinalized) {
                                        titleTag = Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                                          child: Text('확정', style: GoogleFonts.notoSansKr(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB))),
                                        );
                                      } else {
                                        titleTag = Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                          child: Text('누적중', style: GoogleFonts.notoSansKr(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                                        );
                                      }
                                      
                                      return _recurringItem(
                                        context, state,
                                        iconBgColor: const Color(0xFFFFF1F2),
                                        iconColor: const Color(0xFFE11D48),
                                        title: '${c.name} 대금 결제',
                                        titleTag: titleTag,
                                        subtitle: subtitle,
                                        amount: cardPaymentAmount,
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                                secondChild: const SizedBox(width: double.infinity),
                                crossFadeState: _isRecurringExpenseExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                                duration: const Duration(milliseconds: 200),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  ),

                  // ---- 이번 달 고정 수입 내역 ----
                  Builder(
                    builder: (context) {
                      final Map<String, Transaction> recurringMap = {};
                      for (final t in state.transactions) {
                        if (t.isRecurring && t.recurringId != null && t.type == 'income') {
                          recurringMap[t.recurringId!] = t;
                        }
                      }
                      final recurringTxs = recurringMap.values.toList();
                      
                      if (recurringTxs.isEmpty) return const SizedBox.shrink();

                      int totalIncome = recurringTxs.fold(0, (sum, tx) => sum + (tx.amount ?? 0));

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() => _isRecurringIncomeExpanded = !_isRecurringIncomeExpanded);
                                  SharedPreferences.getInstance().then((prefs) => prefs.setBool('isRecurringIncomeExpanded', _isRecurringIncomeExpanded));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                                  child: Row(
                                    children: [
                                      Text('이번 달 고정 수입', style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                                      const Spacer(),
                                      Text(formatNumber(totalIncome), style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF059669), fontWeight: FontWeight.w700)),
                                      const SizedBox(width: 8),
                                      Icon(_isRecurringIncomeExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 16, color: const Color(0xFF94A3B8)),
                                    ],
                                  ),
                                ),
                              ),
                              AnimatedCrossFade(
                                firstChild: Column(
                                  children: [
                                    ...recurringTxs.map((tx) {
                                      return _recurringItem(
                                        context, state,
                                        iconBgColor: const Color(0xFFECFDF5),
                                        iconColor: const Color(0xFF059669),
                                        title: tx.memo.isNotEmpty ? '${tx.category} (${tx.memo})' : tx.category,
                                        subtitle: '${state.currentDate.month}/${int.tryParse(tx.date.split('-').last) ?? 0}',
                                        amount: tx.amount,
                                        onDelete: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              backgroundColor: const Color(0xFFFFFFFF),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              title: Text('고정 수입 삭제', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: const Color(0xFFE11D48))),
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
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                                secondChild: const SizedBox(width: double.infinity),
                                crossFadeState: _isRecurringIncomeExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                                duration: const Duration(milliseconds: 200),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  ),

                  // ---- 등록 계좌/카드 ----
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() => _isAccountsExpanded = !_isAccountsExpanded);
                              SharedPreferences.getInstance().then((prefs) => prefs.setBool('isAccountsExpanded', _isAccountsExpanded));
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                              child: Row(
                                children: [
                                  Text('등록 계좌/카드', style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 4),
                                  Text('(${state.accounts.length})', style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
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
                                  Icon(_isAccountsExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 16, color: const Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                          ),
                          AnimatedCrossFade(
                            firstChild: Column(
                              children: [
                                ...state.accounts.map((acc) {
                                  int? amount;
                                  String subLabel = '';
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
                                    subLabel = '[통장] ${acc.bank}';
                                  } else if (acc.isCredit) {
                                    amount = null;
                                    final cardInfo = state.getCardPaymentInfo(acc, state.currentDate.year, state.currentDate.month);
                                    subLabel = '[신용] ${acc.bank} | ${cardInfo.startStr.replaceAll('.', '/')}~${cardInfo.endStr.replaceAll('.', '/')} | ${cardInfo.paymentDateStr.replaceAll('.', '/')}';
                                  } else if (acc.isDebit) {
                                    amount = null;
                                    subLabel = '[체크] ${acc.bank}';
                                  }
                                  
                                  return _accountCheckItem(
                                    context, state,
                                    id: acc.id,
                                    icon: acc.isCredit ? Icons.credit_card : acc.isDebit ? Icons.credit_card : Icons.account_balance,
                                    label: acc.name,
                                    subLabel: subLabel,
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
                                const SizedBox(height: 8),
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cashFlowRow(
    BuildContext context, AppState state, String filterKey, IconData icon, Color color, Color bgColor, String title, int amount,
    bool isExpanded, VoidCallback onTap, List<Widget> children
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFF334155), fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${formatNumber(amount)}원', style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              const SizedBox(width: 8),
              Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 16, color: const Color(0xFF94A3B8)),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children.isNotEmpty 
              ? children.map((w) => Padding(padding: const EdgeInsets.only(top: 8, left: 36), child: w)).toList()
              : [Padding(padding: const EdgeInsets.only(top: 8, left: 36), child: Text('내역 없음', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF94A3B8))))],
          ),
          secondChild: const SizedBox(width: double.infinity),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _recurringItem(BuildContext context, AppState state, {
    required Color iconBgColor, required Color iconColor, required String title, Widget? titleTag, required String subtitle, required int? amount, Widget? rightWidget, VoidCallback? onDelete
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_today, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                    if (titleTag != null) ...[
                      const SizedBox(width: 6),
                      titleTag,
                    ],
                  ],
                ),
                Text(subtitle, style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          if (amount != null)
            Text('${formatNumber(amount)}원', style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
          if (rightWidget != null)
            rightWidget,
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.delete_outline, size: 16, color: Color(0xFF94A3B8)),
              ),
            ),
        ],
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
              child: isChecked ? const Icon(Icons.check, size: 12, color: Color(0xFFFFFFFF)) : null,
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
