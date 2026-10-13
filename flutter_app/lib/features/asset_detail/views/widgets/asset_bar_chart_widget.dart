import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/features/asset_detail/models/monthly_asset_data.dart';
import 'package:flutter_app/features/asset_detail/models/asset_view_mode.dart';
import 'package:flutter_app/core/utils/helpers.dart';

class AssetBarChartWidget extends StatefulWidget {
  final AssetViewMode viewMode;
  final List<MonthlyAssetData> dataList;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  const AssetBarChartWidget({
    super.key,
    required this.viewMode,
    required this.dataList,
    required this.selectedDate,
    required this.onSelectDate,
  });

  @override
  State<AssetBarChartWidget> createState() => _AssetBarChartWidgetState();
}

class _AssetBarChartWidgetState extends State<AssetBarChartWidget> {
  late final ScrollController _scrollController;
  final double _barChartHeight = 180.0;
  final double _barWidth = 42.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate(animate: false);
    });
  }

  @override
  void didUpdateWidget(covariant AssetBarChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewMode != widget.viewMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedDate(animate: true);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate({bool animate = true}) {
    if (!_scrollController.hasClients || widget.dataList.isEmpty) return;

    final selectedIdx = widget.dataList.indexWhere((d) {
      if (widget.viewMode == AssetViewMode.monthly) {
        return d.date.year == widget.selectedDate.year && d.date.month == widget.selectedDate.month;
      } else {
        return d.date.year == widget.selectedDate.year;
      }
    });

    if (selectedIdx != -1) {
      final screenWidth = MediaQuery.of(context).size.width;
      final itemWidth = (screenWidth - 32) / 4.8;
      // 선택된 항목이 화면 중앙에 오도록 스크롤
      final targetOffset = (selectedIdx * itemWidth) - (screenWidth / 2) + (itemWidth / 2) + 16;
      final clampedOffset = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

      if (animate) {
        _scrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(clampedOffset);
      }
    }
  }

  void _scrollByStep(int direction) {
    if (!_scrollController.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 32) / 4.8;
    final target = _scrollController.offset + (direction * itemWidth * 2);
    final clamped = target.clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataList.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    // 한 화면에 약 4.8개가 보이도록 하여 자연스럽게 옆으로 스크롤됨을 시각적으로 유도
    final itemWidth = (screenWidth - 32) / 4.8;

    // 실제 자산 최고액 기준 동적 Y축 스케일 계산
    final maxAsset = widget.dataList.map((d) => d.totalAsset).fold<int>(0, (m, v) => v > m ? v : m);
    final yMax = _calculateYAxisMax(maxAsset);
    final yMid = (yMax * 2) ~/ 3;
    final yLow = yMax ~/ 3;

    final currentYear = widget.selectedDate.year.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 기준 연도 및 좌우 화살표 내비게이션 바
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentYear,
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _scrollByStep(-1),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left_rounded, size: 18, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _scrollByStep(1),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 2. 통합 가로 스크롤 영역 (고정 배경 Y축 가이드선 + 스크롤되는 막대 및 캡슐 날짜)
        SizedBox(
          height: _barChartHeight + 46, // 막대 높이(180) + 하단 캡슐 날짜(46)
          child: Stack(
            children: [
              // 배경 고정 수평 가이드선 및 우측 Y축 레이블
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 46), // 날짜 높이 제외
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGuideLine(yMax),
                      _buildGuideLine(yMid),
                      _buildGuideLine(yLow),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                    ],
                  ),
                ),
              ),

              // 가로 스크롤 가능한 막대 + 날짜 캡슐 목록 (자연스러운 제스처 스크롤)
              Positioned.fill(
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.dataList.length,
                  itemBuilder: (context, index) {
                    final item = widget.dataList[index];
                    final isSelected = widget.viewMode == AssetViewMode.monthly
                        ? (item.date.year == widget.selectedDate.year && item.date.month == widget.selectedDate.month)
                        : (item.date.year == widget.selectedDate.year);

                    return SizedBox(
                      width: itemWidth,
                      child: Column(
                        children: [
                          // 상단: 막대 영역
                          SizedBox(
                            height: _barChartHeight,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _buildSmoothBar(item, isSelected, yMax),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 하단: 블랙 캡슐 알약 날짜 버튼
                          _buildDatePill(item, isSelected),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 가이드라인 및 Y축 눈금선 (동적 계산)
  // -------------------------------------------------------------
  Widget _buildGuideLine(int amount) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: Color(0xFFF1F5F9), height: 1),
        ),
        const SizedBox(width: 6),
        Text(
          '₩${formatCompactNumber(amount)}',
          style: GoogleFonts.notoSansKr(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // -------------------------------------------------------------
  // 모서리가 절대 깨지지 않는 완벽한 라운딩 스택 막대
  // -------------------------------------------------------------
  Widget _buildSmoothBar(MonthlyAssetData item, bool isSelected, int yMax) {
    final double maxBarHeight = _barChartHeight - 12.0;
    const double minBarHeight = 32.0;

    // 실제 총 자산에 비례한 전체 막대 높이
    final assetRatio = yMax > 0 ? (item.totalAsset.clamp(0, yMax) / yMax) : 0.0;
    final totalBarHeight = minBarHeight + (maxBarHeight - minBarHeight) * assetRatio;

    // 수입과 지출 비율 (예정 포함 총액)
    final totalFlow = item.totalIncome + item.totalExpense;
    final incomeRatio = totalFlow > 0 ? (item.totalIncome / totalFlow) : 0.5;
    final expenseRatio = totalFlow > 0 ? (item.totalExpense / totalFlow) : 0.5;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onSelectDate(item.date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: _barWidth,
        height: totalBarHeight,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          // 바깥 틀에 일체형 테두리를 적용하여 안티앨리어싱 깨짐 완전 방지
          border: Border.all(
            color: isSelected ? const Color(0xFFD81B60) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD81B60).withOpacity(0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          child: Column(
            children: [
              // 상단: 지출 블록 (연한 핑크 솔리드)
              if (expenseRatio > 0)
                Expanded(
                  flex: (expenseRatio * 1000).toInt().clamp(1, 1000),
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFFCE4EC),
                  ),
                ),

              // 수입과 지출 사이 얇은 경계선
              if (expenseRatio > 0 && incomeRatio > 0)
                Container(
                  height: 1.2,
                  color: isSelected ? const Color(0xFFD81B60) : const Color(0xFFF48FB1),
                ),

              // 하단: 수입 블록 (진한 마젠타 그라데이션)
              if (incomeRatio > 0)
                Expanded(
                  flex: (incomeRatio * 1000).toInt().clamp(1, 1000),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE91E63),
                          Color(0xFFAD1457),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 하단 블랙 캡슐 알약 날짜 버튼
  // -------------------------------------------------------------
  Widget _buildDatePill(MonthlyAssetData item, bool isSelected) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onSelectDate(item.date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          item.label,
          style: GoogleFonts.notoSansKr(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // 자산 최대치에 맞는 적절한 Y축 상한선(올림) 유연한 동적 계산
  int _calculateYAxisMax(int maxAsset) {
    if (maxAsset <= 0) return 3000000;
    // 막대가 차트 최상단에 닿지 않도록 약 15% 여유 공간 확보
    final target = (maxAsset * 1.15).toInt();

    // 자산 규모에 맞춘 세밀한 올림 스텝 (100만 / 200만 / 500만 / 1000만)
    int step;
    if (target <= 5000000) {
      step = 1000000; // 100만 단위
    } else if (target <= 30000000) {
      step = 2000000; // 200만 단위 (예: 2,200만, 2,400만 등)
    } else if (target <= 100000000) {
      step = 5000000; // 500만 단위
    } else {
      step = 10000000; // 1,000만 단위
    }

    return ((target + step - 1) ~/ step) * step;
  }
}
