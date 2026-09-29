import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/drawer/dashboard/view_models/dashboard_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';
import 'package:flutter_app/features/drawer/dashboard/views/widgets/asset_summary_card_ui.dart';

class AssetSummaryCard extends StatefulWidget {
  const AssetSummaryCard({super.key});

  @override
  State<AssetSummaryCard> createState() => _AssetSummaryCardState();
}

class _AssetSummaryCardState extends State<AssetSummaryCard> {
  bool _isAssetVisible = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAssetVisible = prefs.getBool('isAssetVisible') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UiViewModel>(
      builder: (context, uiState, _) {
        return AssetSummaryCardUI(
          isAssetVisible: _isAssetVisible,
          assetReferenceDate: uiState.assetReferenceDate,
          totalAssets: context.read<DashboardViewModel>().getFilteredNetAssets(),
          onToggleVisibility: () {
            setState(() => _isAssetVisible = !_isAssetVisible);
            SharedPreferences.getInstance().then((prefs) => prefs.setBool('isAssetVisible', _isAssetVisible));
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


