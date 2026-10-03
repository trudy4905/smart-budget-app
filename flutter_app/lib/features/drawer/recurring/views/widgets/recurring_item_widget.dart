import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/utils/helpers.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class RecurringItemWidget extends StatelessWidget {
  final String title;
  final Widget? titleTag;
  final String subtitle;
  final int? amount;
  final Widget? rightWidget;
  final VoidCallback? onDelete;
  final IconData? icon;
  final String? emoji;
  final Color? iconColor;
  final bool isSubItem;

  const RecurringItemWidget({
    super.key,
    required this.title,
    this.titleTag,
    required this.subtitle,
    this.amount,
    this.rightWidget,
    this.onDelete,
    this.icon,
    this.emoji,
    this.iconColor,
    this.isSubItem = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 14, top: 7, bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isSubItem)
            const Padding(
              padding: EdgeInsets.only(left: 4, right: 6),
              child: Icon(Icons.subdirectory_arrow_right, size: 14, color: Color(0xFFCBD5E1)),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (emoji != null && emoji!.isNotEmpty) ...[
                      Text(emoji!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                    ] else if (icon != null) ...[
                      Icon(icon, size: 14, color: iconColor ?? AppColors.textSub),
                      const SizedBox(width: 5),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (titleTag != null) ...[
                      const SizedBox(width: 6),
                      titleTag!,
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.notoSansKr(fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          if (amount != null) ...[
            Text(
              '${formatNumber(amount!)}원',
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (rightWidget != null) rightWidget!,
          if (onDelete != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textHint),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: AppColors.surface,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (val) {
                if (val == 'delete') onDelete?.call();
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 16, color: AppColors.expense),
                      const SizedBox(width: 8),
                      Text(
                        '삭제',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          color: AppColors.expense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
