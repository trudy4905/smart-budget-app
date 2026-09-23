import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/helpers.dart';

class RecurringItemWidget extends StatelessWidget {
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final Widget? titleTag;
  final String subtitle;
  final int? amount;
  final Widget? rightWidget;
  final VoidCallback? onDelete;

  const RecurringItemWidget({
    super.key, required this.iconBgColor, required this.iconColor, required this.title,
    this.titleTag, required this.subtitle, this.amount, this.rightWidget, this.onDelete
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                      titleTag!,
                    ],
                  ],
                ),
                Text(subtitle, style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          if (amount != null)
            Text('${formatNumber(amount!)}원', style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
          if (rightWidget != null)
            rightWidget!,
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
}
