import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/drawer/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';
import 'package:flutter_app/features/drawer/dashboard/views/widgets/asset_summary_card_ui.dart';

class AssetSummaryCard extends StatelessWidget {
  const AssetSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UiViewModel>(
      builder: (context, uiState, _) {
        return AssetSummaryCardUI(
          isAssetVisible: uiState.isAssetVisible,
          assetReferenceDate: uiState.assetReferenceDate,
          totalAssets: context.read<DashboardViewModel>().getFilteredNetAssets(),
          onToggleVisibility: () {
            uiState.toggleAssetVisible();
          },
          onChangeDate: (date) => uiState.setAssetReferenceDate(date),
          onShowDatePicker: (context, initialDate) => showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          ),
        );
      },
    );
  }
}
