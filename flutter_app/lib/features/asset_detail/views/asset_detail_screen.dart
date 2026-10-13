import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/drawer/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter_app/features/categories/view_models/category_view_model.dart';
import 'package:flutter_app/features/asset_detail/view_models/asset_detail_view_model.dart';
import 'package:flutter_app/features/asset_detail/views/widgets/summary_header_widget.dart';
import 'package:flutter_app/features/asset_detail/views/widgets/asset_bar_chart_widget.dart';
import 'package:flutter_app/features/asset_detail/views/widgets/asset_detail_card_widget.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class AssetDetailScreen extends StatelessWidget {
  const AssetDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AssetDetailViewModel>(
      create: (context) => AssetDetailViewModel(
        dashboardVM: Provider.of<DashboardViewModel>(context, listen: false),
        categoryVM: Provider.of<CategoryViewModel>(context, listen: false),
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
    final dataList = viewModel.getDataList();
    final selectedData = viewModel.getSelectedData();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textMain, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '자산 및 실적 통계',
          style: GoogleFonts.notoSansKr(
            fontSize: 16,
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
              // 1. 요약 타이틀 & 보기 방식 드롭다운 칩 (우측 메뉴 아이콘 없음)
              SummaryHeaderWidget(
                viewMode: viewModel.viewMode,
                onViewModeChanged: viewModel.setViewMode,
              ),

              const SizedBox(height: 8),

              // 2. 레퍼런스 스타일 막대 차트 (실제 자산 비례 Y축 눈금선 + 스택 막대 + 날짜 선택 바)
              AssetBarChartWidget(
                viewMode: viewModel.viewMode,
                dataList: dataList,
                selectedDate: viewModel.selectedDate,
                onSelectDate: viewModel.selectDate,
              ),

              const SizedBox(height: 16),

              // 3. 하단 상세 정보 카드 (수입/지출 총액 + 순흐름 + 총 자산 + 2단 아코디언)
              AssetDetailCardWidget(data: selectedData),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
