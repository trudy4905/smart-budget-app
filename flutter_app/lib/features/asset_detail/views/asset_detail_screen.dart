import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/drawer/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter_app/features/asset_detail/view_models/asset_detail_view_model.dart';
import 'package:flutter_app/features/asset_detail/views/widgets/monthly_asset_bar_chart.dart';
import 'package:flutter_app/features/asset_detail/views/widgets/monthly_detail_breakdown.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class AssetDetailScreen extends StatelessWidget {
  const AssetDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AssetDetailViewModel>(
      create: (context) => AssetDetailViewModel(
        Provider.of<DashboardViewModel>(context, listen: false),
      ),
      child: const _AssetDetailScreenView(),
    );
  }
}

class _AssetDetailScreenView extends StatelessWidget {
  const _AssetDetailScreenView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AssetDetailViewModel>();
    final dataList = viewModel.getMonthlyDataList();
    final selectedData = viewModel.getSelectedMonthData();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textMain, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '자산 및 소비 통계',
          style: GoogleFonts.notoSansKr(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              
              // 섹션 타이틀
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '월별 자산 및 흐름 추이',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      '좌우로 스크롤하여 확인',
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // 가로 스크롤 막대그래프 (총 4달치 뷰)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: MonthlyAssetBarChart(
                  dataList: dataList,
                  selectedMonth: viewModel.selectedMonth,
                  onSelectMonth: viewModel.selectMonth,
                ),
              ),

              const SizedBox(height: 8),

              // 선택된 월의 디테일 정보 표시
              MonthlyDetailBreakdown(data: selectedData),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
