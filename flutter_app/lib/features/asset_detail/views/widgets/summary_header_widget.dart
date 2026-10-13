import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/features/asset_detail/models/asset_view_mode.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class SummaryHeaderWidget extends StatelessWidget {
  final AssetViewMode viewMode;
  final ValueChanged<AssetViewMode> onViewModeChanged;

  const SummaryHeaderWidget({
    super.key,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final modeLabel = viewMode == AssetViewMode.monthly ? '월별 보기' : '년도별 보기';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 볼드 '요약' 타이틀 (우측 메뉴 아이콘 없음)
          Text(
            '요약',
            style: GoogleFonts.notoSansKr(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),

          // 2. '월별 보기 ▾' / '년도별 보기 ▾' 드롭다운 칩
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showViewModePicker(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  modeLabel,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSub,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textSub,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showViewModePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '보기 방식 선택',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(
                    Icons.calendar_view_month_rounded,
                    color: viewMode == AssetViewMode.monthly ? const Color(0xFF4F46E5) : AppColors.textSub,
                  ),
                  title: Text(
                    '월별 보기',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 15,
                      fontWeight: viewMode == AssetViewMode.monthly ? FontWeight.w700 : FontWeight.w500,
                      color: viewMode == AssetViewMode.monthly ? const Color(0xFF4F46E5) : AppColors.textMain,
                    ),
                  ),
                  trailing: viewMode == AssetViewMode.monthly
                      ? const Icon(Icons.check_rounded, color: Color(0xFF4F46E5))
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    onViewModeChanged(AssetViewMode.monthly);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.calendar_today_rounded,
                    color: viewMode == AssetViewMode.yearly ? const Color(0xFF4F46E5) : AppColors.textSub,
                  ),
                  title: Text(
                    '년도별 보기',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 15,
                      fontWeight: viewMode == AssetViewMode.yearly ? FontWeight.w700 : FontWeight.w500,
                      color: viewMode == AssetViewMode.yearly ? const Color(0xFF4F46E5) : AppColors.textMain,
                    ),
                  ),
                  trailing: viewMode == AssetViewMode.yearly
                      ? const Icon(Icons.check_rounded, color: Color(0xFF4F46E5))
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    onViewModeChanged(AssetViewMode.yearly);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
