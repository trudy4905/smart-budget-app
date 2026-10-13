import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/features/asset_detail/models/monthly_asset_data.dart';
import 'package:flutter_app/core/utils/helpers.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class MonthlyAssetBarChart extends StatefulWidget {
  final List<MonthlyAssetData> dataList;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onSelectMonth;

  const MonthlyAssetBarChart({
    super.key,
    required this.dataList,
    required this.selectedMonth,
    required this.onSelectMonth,
  });

  @override
  State<MonthlyAssetBarChart> createState() => _MonthlyAssetBarChartState();
}

class _MonthlyAssetBarChartState extends State<MonthlyAssetBarChart> {
  late final ScrollController _scrollController;
  final double _barHeight = 150.0;
  final double _barWidth = 38.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentMonth();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentMonth() {
    if (!_scrollController.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 32) / 4.0;
    
    // 현재 월의 인덱스 찾기
    final currentIndex = widget.dataList.indexWhere((d) => d.isCurrentMonth);
    if (currentIndex != -1) {
      // 현재 월이 화면 2~3번째에 오도록 스크롤
      final targetOffset = (currentIndex - 1.5) * itemWidth;
      final clampedOffset = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 한 화면에 약 4달치가 균형 있게 들어오도록 너비 지정
    final itemWidth = (screenWidth - 32) / 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 범례 (Legend)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegendItem('수입', const Color(0xFF10B981)),
              const SizedBox(width: 14),
              _buildLegendItem('지출', const Color(0xFFF43F5E)),
            ],
          ),
        ),

        // 가로 스크롤 막대그래프 영역
        SizedBox(
          height: 240,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.dataList.length,
            itemBuilder: (context, index) {
              final item = widget.dataList[index];
              final isSelected = item.month.year == widget.selectedMonth.year &&
                  item.month.month == widget.selectedMonth.month;

              return SizedBox(
                width: itemWidth,
                child: _buildBarColumn(item, isSelected),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSub,
          ),
        ),
      ],
    );
  }

  Widget _buildBarColumn(MonthlyAssetData item, bool isSelected) {
    final totalFlow = item.totalIncome + item.totalExpense;
    final incomeRatio = totalFlow > 0 ? (item.totalIncome / totalFlow) : 0.0;
    final expenseRatio = totalFlow > 0 ? (item.totalExpense / totalFlow) : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onSelectMonth(item.month),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 1. 막대 위 총 자산 금액
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatCompactNumber(item.totalAsset),
                style: GoogleFonts.notoSansKr(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  color: isSelected ? const Color(0xFF4F46E5) : AppColors.textMain,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 2. 수입/지출 비율 스택 막대
            Container(
              width: _barWidth,
              height: _barHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: totalFlow == 0
                    ? Center(
                        child: Text(
                          '-',
                          style: GoogleFonts.notoSansKr(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // 상단: 지출 비율 블록
                          if (expenseRatio > 0)
                            Expanded(
                              flex: (expenseRatio * 1000).toInt(),
                              child: Container(
                                width: double.infinity,
                                color: const Color(0xFFF43F5E),
                                alignment: Alignment.center,
                                child: (expenseRatio >= 0.25)
                                    ? Text(
                                        '${(expenseRatio * 100).round()}%',
                                        style: GoogleFonts.notoSansKr(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          // 구분선 (둘 다 있을 경우)
                          if (expenseRatio > 0 && incomeRatio > 0)
                            Container(height: 1, color: Colors.white.withOpacity(0.4)),
                          // 하단: 수입 비율 블록
                          if (incomeRatio > 0)
                            Expanded(
                              flex: (incomeRatio * 1000).toInt(),
                              child: Container(
                                width: double.infinity,
                                color: const Color(0xFF10B981),
                                alignment: Alignment.center,
                                child: (incomeRatio >= 0.25)
                                    ? Text(
                                        '${(incomeRatio * 100).round()}%',
                                        style: GoogleFonts.notoSansKr(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),

            // 3. 월 라벨 (연도 표시 및 이번달 표시)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (item.isCurrentMonth)
                  Container(
                    margin: const EdgeInsets.only(right: 3),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  '${item.month.month}월',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    fontWeight: isSelected || item.isCurrentMonth
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : (item.isCurrentMonth
                            ? AppColors.textMain
                            : AppColors.textSub),
                  ),
                ),
              ],
            ),
            if (item.isFutureMonth)
              Text(
                '예정',
                style: GoogleFonts.notoSansKr(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF818CF8),
                ),
              )
            else
              Text(
                '${item.month.year.toString().substring(2)}년',
                style: GoogleFonts.notoSansKr(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
