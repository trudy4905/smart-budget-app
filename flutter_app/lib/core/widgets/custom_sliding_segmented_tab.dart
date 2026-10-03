import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class SegmentTabItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? activeColor;
  final Color? activeIndicatorColor;

  const SegmentTabItem({
    required this.value,
    required this.label,
    this.icon,
    this.activeColor,
    this.activeIndicatorColor,
  });
}

/// 요즘 유행하는 아이폰(iOS) 스타일의 둥근 물방울/알약(Capsule) 슬라이딩 세그먼트 탭
class CustomSlidingSegmentedTab<T> extends StatelessWidget {
  final List<SegmentTabItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onValueChanged;
  final double height;
  final Color? backgroundColor;

  const CustomSlidingSegmentedTab({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onValueChanged,
    this.height = 44,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final currentIndex = items.indexWhere((item) => item.value == selectedValue);
    final selectedIdx = currentIndex >= 0 ? currentIndex : 0;
    final currentItem = items[selectedIdx];

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFF1F5F9), // iOS 스타일 은은한 배경 트랙
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(3.5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final itemWidth = totalWidth / items.length;
          final itemHeight = constraints.maxHeight;

          return Stack(
            children: [
              // 물방울/알약형 슬라이딩 인디케이터 (Sliding Pill Indicator)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: selectedIdx * itemWidth,
                top: 0,
                width: itemWidth,
                height: itemHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: currentItem.activeIndicatorColor ?? Colors.white,
                    borderRadius: BorderRadius.circular(itemHeight / 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: (currentItem.activeColor ?? AppColors.primary).withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.black.withOpacity(0.04),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
              // 탭 아이템 레이아웃 (아이콘 + 텍스트)
              Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == selectedIdx;
                  final activeTextColor = item.activeColor ?? AppColors.primary;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!isSelected) {
                          HapticFeedback.selectionClick();
                          onValueChanged(item.value);
                        }
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? activeTextColor : AppColors.textSub,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.icon != null) ...[
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    item.icon,
                                    key: ValueKey('${item.value}_$isSelected'),
                                    size: 15,
                                    color: isSelected ? activeTextColor : AppColors.textHint,
                                  ),
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(item.label),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
