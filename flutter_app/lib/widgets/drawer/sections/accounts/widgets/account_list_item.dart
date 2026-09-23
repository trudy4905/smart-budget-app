import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../providers/app_state.dart';
import '../../../../../../utils/helpers.dart';

class AccountListItem extends StatelessWidget {
  final List<String> selectedAccountIds;
  final int totalAccountsCount;
  final void Function(List<String>) onSelectedAccountIdsChanged;
  final String id;
  final IconData icon;
  final String label;
  final String? badgeText;
  final String subLabel;
  final Color color;
  final int? amount;
  final String? thirdLineText;
  final String? rightTopText;
  final String? rightBottomText;
  final bool isAll;
  final bool isSubItem;
  final List<PopupMenuEntry<String>>? popupMenuItems;
  final Function(String)? onAction;

  const AccountListItem({
    super.key,
    required this.selectedAccountIds,
    required this.totalAccountsCount,
    required this.onSelectedAccountIdsChanged,
    required this.id,
    required this.icon,
    required this.label,
    this.badgeText,
    required this.subLabel,
    required this.color,
    this.amount,
    this.thirdLineText,
    this.rightTopText,
    this.rightBottomText,
    this.isAll = false,
    this.isSubItem = false,
    this.popupMenuItems,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isAllActive = selectedAccountIds.contains('all');
    final isChecked = isAll ? isAllActive : (isAllActive || selectedAccountIds.contains(id));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (isAll) {
              if (isAllActive) {
                onSelectedAccountIdsChanged([]);
              } else {
                onSelectedAccountIdsChanged(['all']);
              }
            } else {
              onSelectedAccountIdsChanged([id]); // The parent will handle the toggle logic
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
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
                      amount! >= 0 ? '₩${formatNumber(amount!)}' : '-₩${formatNumber(amount!.abs())}',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: amount! >= 0 ? const Color(0xFF059669) : const Color(0xFFE11D48),
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
}
