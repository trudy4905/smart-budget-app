import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_state.dart';
import '../../models/account.dart';
import '../../utils/helpers.dart';
import '../common/add_account_sheet.dart';

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

  Widget _accountCheckItem(
    BuildContext context, AppState state, {
    required String id,
    required IconData icon,
    required String label,
    String? badgeText,
    required String subLabel,
    required Color color,
    int? amount,
    String? thirdLineText,
    String? rightTopText,
    String? rightBottomText,
    bool isAll = false,
    bool isSubItem = false,
    List<PopupMenuEntry<String>>? popupMenuItems,
    Function(String)? onAction,
  }) {
    final isAllActive = state.selectedAccountIds.contains('all');
    final isChecked = isAll ? isAllActive : (isAllActive || state.selectedAccountIds.contains(id));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
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
            padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
            child: Row(
              children: [
                if (isSubItem)
                  const Padding(
                    padding: EdgeInsets.only(left: 0, right: 4),
                    child: Icon(Icons.subdirectory_arrow_right, size: 16, color: Color(0xFFCBD5E1)),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: isChecked ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: isChecked ? color : const Color(0xFFE2E8F0), width: 1.5),
                  ),
                  child: isChecked ? const Icon(Icons.check, size: 12, color: Color(0xFFFFFFFF)) : null,
                ),
                const SizedBox(width: 12),
                Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(label,
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 13,
                                  color: isChecked ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                  fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                                ), overflow: TextOverflow.ellipsis),
                          ),
                          if (rightTopText != null)
                            Text(rightTopText!, style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (badgeText != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text('[$badgeText]', style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF94A3B8))),
                                  ),
                                Expanded(
                                  child: Text(subLabel, style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                          if (rightBottomText != null)
                            Text(rightBottomText!, style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (amount != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      amount >= 0 ? '₩${formatNumber(amount)}' : '-₩${formatNumber(amount.abs())}',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: amount >= 0 ? const Color(0xFF059669) : const Color(0xFFE11D48),
                      ),
                    ),
                  ),
                if (onAction != null)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, size: 16, color: Color(0xFF94A3B8)),
                    color: const Color(0xFFFFFFFF),
                    onSelected: onAction,
                    itemBuilder: (ctx) => popupMenuItems ?? [
                      PopupMenuItem(value: 'edit', child: Text('수정', style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFF0F172A)))),
                      PopupMenuItem(value: 'delete', child: Text('삭제', style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFFE11D48)))),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(color: Color(0xFFF1F5F9), height: 1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final banks = state.accounts.where((a) => a.isBank).toList();
        final cards = state.accounts.where((a) => !a.isBank).toList();
        
        Widget buildAccNode(Account acc, {bool isSubItem = false}) {
          int? amount;
          String subLabel = '';
          String badgeText = '';
          String? rightTopText;
          String? rightBottomText;

          if (acc.isBank) {
            amount = state.getBankAccountBalance(acc.id, upToDate: DateTime.now());
            badgeText = '통장';
            subLabel = acc.bank;
          } else if (acc.isCredit) {
            amount = null;
            badgeText = '신용';
            subLabel = acc.bank;
            if (acc.billingStartMonth != null && acc.billingStartDay != null && acc.billingEndMonth != null && acc.billingEndDay != null) {
              final startM = acc.billingStartMonth == -1 ? '전월' : '당월';
              final endM = acc.billingEndMonth == -1 ? '전월' : '당월';
              rightTopText = '$startM ${acc.billingStartDay}일 ~ $endM ${acc.billingEndDay}일';
            }
            if (acc.paymentDay != null) {
              rightBottomText = '매월 ${acc.paymentDay}일';
            }
          } else {
            amount = null;
            badgeText = '체크';
            subLabel = acc.bank;
          }

          return _accountCheckItem(
            context, state,
            id: acc.id,
            icon: acc.isBank ? Icons.account_balance : Icons.credit_card,
            label: acc.name,
            badgeText: badgeText,
            subLabel: subLabel,
            color: hexToColor(acc.color),
            amount: amount,
            rightTopText: rightTopText,
            rightBottomText: rightBottomText,
            thirdLineText: null,
            isSubItem: isSubItem,
            onAction: (val) {
              if (val == 'edit') _showAddAccountDialog(context, state, editAccount: acc);
              if (val == 'delete') _showDeleteConfirmation(context, state, acc);
            },
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
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
                            borderRadius: BorderRadius.circular(12),
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
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(color: Color(0xFFF1F5F9), height: 1),
                    ),

                    ...banks.map((b) {
                      final linkedCards = cards.where((c) => c.linkedBankAccountId == b.id).toList();
                      return Column(
                        children: [
                          buildAccNode(b),
                          ...linkedCards.map((c) => buildAccNode(c, isSubItem: true)),
                        ],
                      );
                    }),
                    ...cards.where((c) => c.linkedBankAccountId == null || !banks.any((b) => b.id == c.linkedBankAccountId)).map((c) => buildAccNode(c)),
                    const SizedBox(height: 8),
                  ],
                ),
                secondChild: const SizedBox(width: double.infinity),
                crossFadeState: _isAccountsExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        );
      }
    );
  }
}
