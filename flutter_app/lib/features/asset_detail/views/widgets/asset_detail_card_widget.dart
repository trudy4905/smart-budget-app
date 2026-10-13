import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/features/asset_detail/models/monthly_asset_data.dart';
import 'package:flutter_app/core/utils/helpers.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class AssetDetailCardWidget extends StatelessWidget {
  final MonthlyAssetData data;

  const AssetDetailCardWidget({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final netFlow = data.netFlow;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 카드 상단 헤더 & 기간 타이틀
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.fullTitle,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ● 수입 (예정 포함 합산)
                  _buildSummaryRow(
                    isSolidBullet: true,
                    title: '수입 (예정 포함)',
                    amount: data.totalIncome,
                    color: const Color(0xFFD81B60),
                  ),
                  const SizedBox(height: 14),

                  // ○ 지출 (예정 포함 합산)
                  _buildSummaryRow(
                    isSolidBullet: false,
                    title: '지출 (예정 포함)',
                    amount: data.totalExpense,
                    color: const Color(0xFFD81B60),
                  ),
                  const SizedBox(height: 16),

                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 14),

                  // 순현금흐름 (수입 - 지출)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '순현금흐름 (KRW)',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        netFlow >= 0 ? '+₩${formatNumber(netFlow)}' : '₩${formatNumber(netFlow)}',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: netFlow >= 0 ? const Color(0xFF059669) : const Color(0xFFE11D48),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 해당 기간 총 자산
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '해당 기간 총 자산',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSub,
                        ),
                      ),
                      Text(
                        '₩${formatNumber(data.totalAsset)}',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFFF1F5F9), height: 1),

            // ---------------------------------------------------------
            // [아코디언 1] 수입/지출 상세 내역 ⌵
            // ---------------------------------------------------------
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                title: Text(
                  '수입 / 지출 상세 내역',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSubMetricCard(
                                title: '확정 수입',
                                amount: data.income,
                                color: const Color(0xFF10B981),
                                icon: Icons.south_west_rounded,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSubMetricCard(
                                title: '예정 수입',
                                amount: data.upcomingIncome,
                                color: const Color(0xFF0284C7),
                                icon: Icons.schedule_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSubMetricCard(
                                title: '확정 지출',
                                amount: data.expense,
                                color: const Color(0xFFF43F5E),
                                icon: Icons.north_east_rounded,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSubMetricCard(
                                title: '예정 지출',
                                amount: data.upcomingExpense,
                                color: const Color(0xFFF59E0B),
                                icon: Icons.event_repeat_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFFF1F5F9), height: 1),

            // ---------------------------------------------------------
            // [아코디언 2] 카테고리별 소비 통계 ⌵
            // ---------------------------------------------------------
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                title: Text(
                  '카테고리별 소비 통계',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: data.categorySpendings.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              '해당 기간에 발생한 지출 내역이 없습니다.',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 13,
                                color: AppColors.textSub,
                              ),
                            ),
                          )
                        : Column(
                            children: data.categorySpendings.map((cat) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(cat.emoji, style: const TextStyle(fontSize: 15)),
                                            const SizedBox(width: 8),
                                            Text(
                                              cat.category,
                                              style: GoogleFonts.notoSansKr(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textMain,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '(${(cat.percentage * 100).toStringAsFixed(1)}%)',
                                              style: GoogleFonts.notoSansKr(
                                                fontSize: 12,
                                                color: AppColors.textSub,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '₩${formatNumber(cat.amount)}',
                                          style: GoogleFonts.notoSansKr(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textMain,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: cat.percentage.clamp(0.0, 1.0),
                                        minHeight: 6,
                                        backgroundColor: const Color(0xFFF1F5F9),
                                        valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 솔리드 원 / 테두리 원 요약 행
  Widget _buildSummaryRow({
    required bool isSolidBullet,
    required String title,
    required int amount,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSolidBullet ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMain,
              ),
            ),
          ],
        ),
        Text(
          '₩${formatNumber(amount)}',
          style: GoogleFonts.notoSansKr(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }

  // 서브 메트릭 미니 카드
  Widget _buildSubMetricCard({
    required String title,
    required int amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                title,
                style: GoogleFonts.notoSansKr(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${formatNumber(amount)}원',
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: amount > 0 ? AppColors.textMain : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
