import 'dart:math' as math;
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
  // 한 번에 화면에 보여줄 아이템 개수 (기본 5개)
  final int _windowSize = 5;
  int _startIndex = 0;

  final double _chartHeight = 180.0;
  final double _barWidth = 44.0;

  @override
  void initState() {
    super.initState();
    _updateStartIndexToFitSelected();
  }

  @override
  void didUpdateWidget(covariant AssetBarChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.viewMode != widget.viewMode ||
        oldWidget.dataList.length != widget.dataList.length) {
      _updateStartIndexToFitSelected();
    }
  }

  void _updateStartIndexToFitSelected() {
    if (widget.dataList.isEmpty) return;

    final selectedIdx = widget.dataList.indexWhere((d) {
      if (widget.viewMode == AssetViewMode.monthly) {
        return d.date.year == widget.selectedDate.year && d.date.month == widget.selectedDate.month;
      } else {
        return d.date.year == widget.selectedDate.year;
      }
    });

    if (selectedIdx != -1) {
      // 선택된 항목이 5개 중 중앙(2번째)에 오도록 startIndex 설정
      int targetStart = selectedIdx - 2;
      final maxStart = math.max(0, widget.dataList.length - _windowSize);
      _startIndex = targetStart.clamp(0, maxStart);
    } else {
      _startIndex = 0;
    }
  }

  void _shiftWindow(int delta) {
    final maxStart = math.max(0, widget.dataList.length - _windowSize);
    final next = (_startIndex + delta).clamp(0, maxStart);
    if (next != _startIndex) {
      setState(() {
        _startIndex = next;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataList.isEmpty) return const SizedBox.shrink();

    // 현재 윈도우에 보이는 데이터 슬라이스 (최대 5개)
    final endIndex = math.min(_startIndex + _windowSize, widget.dataList.length);
    final visibleData = widget.dataList.sublist(_startIndex, endIndex);

    // 실제 자산 기준 동적 Y축 스케일 계산
    final maxAsset = widget.dataList.map((d) => d.totalAsset).fold<int>(0, (m, v) => v > m ? v : m);
    final yMax = _calculateYAxisMax(maxAsset);
    final yMid = (yMax * 2) ~/ 3;
    final yLow = yMax ~/ 3;

    final currentYear = widget.selectedDate.year.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 기준 연도 라벨
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            currentYear,
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // 2. 차트 캔버스 (배경 Y축 가이드선 + 스택 막대들)
        SizedBox(
          height: _chartHeight,
          child: Stack(
            children: [
              // 배경 수평 가이드선 및 우측 Y축 레이블 (실제 자산 동적 스케일)
              Positioned.fill(
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

              // 막대 그래픽 리스트
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: visibleData.map((item) {
                      final isSelected = widget.viewMode == AssetViewMode.monthly
                          ? (item.date.year == widget.selectedDate.year && item.date.month == widget.selectedDate.month)
                          : (item.date.year == widget.selectedDate.year);

                      return _buildBarItem(item, isSelected, yMax);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. 하단 X축 날짜 선택 바 (좌우 화살표 + 블랙 캡슐 알약 탭)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              // 왼쪽 화살표
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22, color: Color(0xFF64748B)),
                onPressed: _startIndex > 0 ? () => _shiftWindow(-1) : null,
                splashRadius: 18,
              ),

              // 날짜 항목들
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: visibleData.map((item) {
                    final isSelected = widget.viewMode == AssetViewMode.monthly
                        ? (item.date.year == widget.selectedDate.year && item.date.month == widget.selectedDate.month)
                        : (item.date.year == widget.selectedDate.year);

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onSelectDate(item.date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.label,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 오른쪽 화살표
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF64748B)),
                onPressed: (_startIndex + _windowSize < widget.dataList.length)
                    ? () => _shiftWindow(1)
                    : null,
                splashRadius: 18,
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
  // 개별 막대 위젯 (레퍼런스 디자인 스택 바)
  // -------------------------------------------------------------
  Widget _buildBarItem(MonthlyAssetData item, bool isSelected, int yMax) {
    final double maxBarHeight = _chartHeight - 16.0;
    const double minBarHeight = 30.0;

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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 스택 막대 본체
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: _barWidth,
            height: totalBarHeight,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD81B60).withOpacity(0.25),
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
                  // 상단: 지출 블록 (연한 핑크 배경 + 테두리 라인 느낌)
                  Expanded(
                    flex: (expenseRatio * 1000).toInt().clamp(1, 1000),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE4EC),
                        border: Border(
                          top: const BorderSide(color: Color(0xFFD81B60), width: 1.5),
                          left: const BorderSide(color: Color(0xFFD81B60), width: 1.5),
                          right: const BorderSide(color: Color(0xFFD81B60), width: 1.5),
                          bottom: BorderSide(
                            color: incomeRatio > 0 ? const Color(0xFFD81B60) : Colors.transparent,
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 하단: 수입 블록 (진한 마젠타 솔리드)
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
        ],
      ),
    );
  }

  // 자산 최대치에 맞는 적절한 Y축 상한선(올림) 계산
  int _calculateYAxisMax(int maxAsset) {
    if (maxAsset <= 0) return 6000000;
    if (maxAsset <= 6000000) return 6000000;
    if (maxAsset <= 10000000) return 10000000;
    if (maxAsset <= 20000000) return 20000000;
    if (maxAsset <= 50000000) return 50000000;
    // 그 이상: 1000만 단위 올림
    return ((maxAsset + 9999999) ~/ 10000000) * 10000000;
  }
}
