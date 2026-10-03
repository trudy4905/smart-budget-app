import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/features/drawer/accounts/models/account.dart';
import 'package:flutter_app/core/utils/helpers.dart';
import 'package:flutter_app/features/drawer/accounts/views/widgets/account_list_item.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

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
        onSelectedAccountIdsChanged: (newIds) {
          if (newIds.isEmpty || newIds.contains('all')) {
            onSelectedAccountIdsChanged(newIds);
          } else {
            final toggleId = newIds.first;
            final currentIds = List<String>.from(selectedAccountIds);
            
            if (currentIds.contains('all')) {
              // all was selected -> all except toggleId
              final allIds = [...banks.map((b)=>b.id), ...cards.map((c)=>c.id)];
              allIds.remove(toggleId);
              onSelectedAccountIdsChanged(allIds.isEmpty ? ['all'] : allIds);
            } else {
              if (currentIds.contains(toggleId)) {
                currentIds.remove(toggleId);
                if (currentIds.isEmpty) {
                  onSelectedAccountIdsChanged(['all']);
                } else {
                  onSelectedAccountIdsChanged(currentIds);
                }
              } else {
                currentIds.add(toggleId);
                if (currentIds.length == totalAccountsCount) {
                  onSelectedAccountIdsChanged(['all']);
                } else {
                  onSelectedAccountIdsChanged(currentIds);
                }
              }
            }
          }
        },
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: AppColors.divider.withOpacity(0.8)),
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
                  Text('등록 계좌/카드', style: GoogleFonts.notoSansKr(fontSize: 14, color: AppColors.textMain, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Text('($totalAccountsCount)', style: GoogleFonts.notoSansKr(fontSize: 14, color: AppColors.textSub, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: onAddClick,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('추가', style: GoogleFonts.notoSansKr(fontSize: 11, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 16, color: AppColors.textHint),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: AppColors.background, height: 1),
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
                Builder(
                  builder: (context) {
                    final unlinked = cards.where((c) => c.linkedBankAccountId == null || !banks.any((b) => b.id == c.linkedBankAccountId)).toList();
                    if (unlinked.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              const SizedBox(width: 8, child: Divider(color: AppColors.divider, thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text('미연결 계좌/카드 (${unlinked.length})', style: GoogleFonts.notoSansKr(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w600)),
                              ),
                              const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
                            ],
                          ),
                        ),
                        ...unlinked.map((c) => buildAccNode(c)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
            secondChild: const SizedBox(width: double.infinity),
            crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    ));
  }
}
