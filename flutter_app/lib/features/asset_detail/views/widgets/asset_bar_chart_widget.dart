import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/features/asset_detail/models/monthly_asset_data.dart';
import 'package:flutter_app/features/asset_detail/models/asset_view_mode.dart';

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
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate(animate: false);
    });
  }

  void _onScroll() {
    if (mounted) {
      setState(() {});
    }
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
    _scrollController.removeListener(_onScroll);
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
      const double yAxisWidth = 76.0;
      final itemWidth = (screenWidth - 16 - yAxisWidth) / 4.2;
      final scrollAreaWidth = screenWidth - yAxisWidth;
      // 선택된 항목이 스크롤 가용 영역 중앙에 오도록 스크롤
      final targetOffset = (selectedIdx * itemWidth) - (scrollAreaWidth / 2) + (itemWidth / 2) + 16;
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
    const double yAxisWidth = 76.0;
    final itemWidth = (screenWidth - 16 - yAxisWidth) / 4.2;
    final target = _scrollController.offset + (direction * itemWidth * 2);
    final clamped = target.clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  // 현재 화면(가시 영역)에 보이는 데이터들의 최대 자산 금액을 계산
  int _getVisibleMaxAsset(double itemWidth, double scrollAreaWidth) {
    if (widget.dataList.isEmpty) return 30000000;

    int startIndex = 0;
    int endIndex = widget.dataList.length;

    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      startIndex = (offset / itemWidth).floor().clamp(0, widget.dataList.length - 1);
      final visibleCount = (scrollAreaWidth / itemWidth).ceil() + 1;
      endIndex = (startIndex + visibleCount).clamp(0, widget.dataList.length);
    } else {
      final selectedIdx = widget.dataList.indexWhere((d) {
        if (widget.viewMode == AssetViewMode.monthly) {
          return d.date.year == widget.selectedDate.year && d.date.month == widget.selectedDate.month;
        } else {
          return d.date.year == widget.selectedDate.year;
        }
      });
      if (selectedIdx != -1) {
        startIndex = (selectedIdx - 2).clamp(0, widget.dataList.length - 1);
        endIndex = (selectedIdx + 3).clamp(0, widget.dataList.length);
      }
    }

    final visibleItems = widget.dataList.sublist(startIndex, endIndex);
    if (visibleItems.isEmpty) return widget.dataList.first.totalAsset;

    return visibleItems.map((d) => d.totalAsset).fold<int>(0, (m, v) => v > m ? v : m);
  }

  // 현재 화면 중앙에 위치한 연도 계산
  int _getDisplayedYear(double itemWidth, double scrollAreaWidth) {
    if (!_scrollController.hasClients || widget.dataList.isEmpty) {
      return widget.selectedDate.year;
    }
    final offset = _scrollController.offset;
    final centerIndex = ((offset + scrollAreaWidth / 2) / itemWidth).floor().clamp(0, widget.dataList.length - 1);
    return widget.dataList[centerIndex].date.year;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataList.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    const double yAxisWidth = 76.0;
    final scrollAreaWidth = screenWidth - 16 - yAxisWidth;
    // 우측 Y축 레이블 공간을 제외한 가용 너비 기준으로 아이템 너비 계산
    final itemWidth = scrollAreaWidth / 4.2;

    // 현재 화면에 보이는 구간의 최대 금액을 기준으로 Y축 스케일 동적 산출 (바닥에 붙지 않고 꽉 차게 표시)
    final visibleMax = _getVisibleMaxAsset(itemWidth, scrollAreaWidth);
    final yMax = _calculateYAxisMax(visibleMax);
    final yMid = (yMax * 2) ~/ 3;
    final yLow = yMax ~/ 3;

    final displayedYear = _getDisplayedYear(itemWidth, scrollAreaWidth).toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 기준 연도 및 좌우 화살표 내비게이션 바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayedYear,
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

          // 2. 통합 가로 차트 영역 (배경 가이드선 + 독립 Y축 금액 레이블 + 좌측 스크롤 막대)
          SizedBox(
            height: _barChartHeight + 46, // 막대 높이(180) + 하단 캡슐 날짜(46)
            child: Stack(
              children: [
                // 배경 수평 가이드선 (화면 전체 너비에 걸쳐 연하게 깔림)
                const Positioned(
                  left: 4,
                  right: 4,
                  top: 0,
                  bottom: 46,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Divider(color: Color(0xFFF1F5F9), height: 1),
                      Divider(color: Color(0xFFF1F5F9), height: 1),
                      Divider(color: Color(0xFFF1F5F9), height: 1),
                      Divider(color: Color(0xFFF1F5F9), height: 1),
                    ],
                  ),
                ),

                // 가로 스크롤 막대 + 날짜 캡슐 목록 (우측 Y축 금액 영역을 침범하지 않도록 right: yAxisWidth로 제한)
                Positioned(
                  left: 0,
                  right: yAxisWidth,
                  top: 0,
                  bottom: 0,
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
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
                            // 상단: 막대 영역 (하단에 6px 여백을 두어 바닥에 붙지 않고 쾌적하게 꽉 차도록 렌더링)
                            SizedBox(
                              height: _barChartHeight,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: _buildSmoothBar(item, isSelected, yMax),
                                ),
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

                // 독립된 우측 고정 Y축 금액 레이블 (막대에 가려지지 않음)
                Positioned(
                  right: 4,
                  top: 0,
                  bottom: 46,
                  width: yAxisWidth - 10,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildYLabel(yMax),
                      _buildYLabel(yMid),
                      _buildYLabel(yLow),
                      const SizedBox(height: 1),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Y축 텍스트 레이블 위젯 (3천, 3억 등 가장 앞자리 단위만 표시)
  Widget _buildYLabel(int amount) {
    return Text(
      _formatLeadingUnit(amount),
      style: GoogleFonts.notoSansKr(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF94A3B8),
      ),
    );
  }

  // 가장 앞자리 단위 표시 (예: 억원, 천만원, 백만원, 만원, 천원, 백원, 원)
  String _formatLeadingUnit(int n) {
    if (n <= 0) return '0원';
    if (n >= 100000000) {
      final eok = n ~/ 100000000;
      final remain = (n % 100000000) ~/ 10000000;
      if (remain > 0) {
        return '$eok억$remain천만';
      }
      return '$eok억원';
    } else if (n >= 10000000) {
      final cheon = n ~/ 10000000;
      final remain = (n % 10000000) ~/ 1000000;
      if (remain > 0) {
        return '$cheon천$remain백만';
      }
      return '$cheon천만원';
    } else if (n >= 1000000) {
      final baek = n ~/ 1000000;
      return '$baek백만원';
    } else if (n >= 10000) {
      final man = n ~/ 10000;
      return '$man만원';
    } else if (n >= 1000) {
      final cheon = n ~/ 1000;
      return '$cheon천원';
    } else if (n >= 100) {
      final baek = n ~/ 100;
      return '$baek백원';
    }
    return '$n원';
  }

  // -------------------------------------------------------------
  // 모서리가 절대 깨지지 않는 완벽한 라운딩 스택 막대
  // -------------------------------------------------------------
  Widget _buildSmoothBar(MonthlyAssetData item, bool isSelected, int yMax) {
    final double maxBarHeight = _barChartHeight - 16.0;
    const double minBarHeight = 44.0; // 최소 높이를 도톰하게 주어 바닥에 납작하게 붙지 않게 함

    // 가시 영역 기준 총 자산 비례 막대 높이 계산
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

  // 자산 최대치에 맞는 적절한 Y축 상한선 (갑자기 3억으로 점프하지 않고, 최대치에 약간의 여유를 둔 후 최적 단위로 계산)
  int _calculateYAxisMax(int maxAsset) {
    if (maxAsset <= 0) return 30000000;
    final target = (maxAsset * 1.08).toInt();

    int step;
    if (target <= 10000000) {
      step = 2000000; // 2백만원 단위
    } else if (target <= 30000000) {
      step = 5000000; // 5백만원 단위 (1500만, 2000만, 2500만, 3000만)
    } else if (target <= 60000000) {
      step = 10000000; // 1천만원 단위 (4천만, 5천만, 6천만)
    } else if (target <= 100000000) {
      step = 20000000; // 2천만원 단위 (8천만, 1억)
    } else if (target <= 200000000) {
      step = 25000000; // 2천5백만원 단위 (1억2500만, 1억5000만, 1억7500만, 2억)
    } else {
      step = 50000000; // 5천만원 단위
    }

    final rounded = ((target + step - 1) ~/ step) * step;
    return rounded > 0 ? rounded : step;
  }
}
