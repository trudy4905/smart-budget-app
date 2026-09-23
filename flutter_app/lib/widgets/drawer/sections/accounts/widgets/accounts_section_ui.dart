import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../models/account.dart';
import '../../../../../utils/helpers.dart';
import 'account_list_item.dart';

class AccountsSectionUI extends StatelessWidget {
  final List<Account> banks;
  final List<Account> cards;
  final bool isExpanded;
  final int Function(String accountId) getBankAccountBalance;
  final List<String> selectedAccountIds;
  final int totalAccountsCount;
  final void Function(List<String>) onSelectedAccountIdsChanged;
  final VoidCallback onToggleExpanded;
  final VoidCallback onAddClick;
  final void Function(Account account) onEditClick;
  final void Function(Account account) onDeleteClick;

  const AccountsSectionUI({
    super.key,
    required this.banks,
    required this.cards,
    required this.isExpanded,
    required this.getBankAccountBalance,
    required this.selectedAccountIds,
    required this.totalAccountsCount,
    required this.onSelectedAccountIdsChanged,
    required this.onToggleExpanded,
    required this.onAddClick,
    required this.onEditClick,
    required this.onDeleteClick,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildAccNode(Account acc, {bool isSubItem = false}) {
      int? amount;
      String subLabel = '';
      String badgeText = '';
      String? rightTopText;
      String? rightBottomText;

      if (acc.isBank) {
        amount = getBankAccountBalance(acc.id);
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

      return AccountListItem(
        selectedAccountIds: selectedAccountIds,
        totalAccountsCount: totalAccountsCount,
        onSelectedAccountIdsChanged: onSelectedAccountIdsChanged,
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
          if (val == 'edit') onEditClick(acc);
          if (val == 'delete') onDeleteClick(acc);
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
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Text('등록 계좌/카드', style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Text('($totalAccountsCount)', style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: onAddClick,
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
                  Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 16, color: const Color(0xFF94A3B8)),
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
            crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
