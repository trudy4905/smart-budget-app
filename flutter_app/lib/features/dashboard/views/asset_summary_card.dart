import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/core/providers/app_state.dart';
import 'package:flutter_app/features/dashboard/views/widgets/asset_summary_card_ui.dart';

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
    return Consumer<AppState>(
      builder: (context, state, _) {
        return AssetSummaryCardUI(
          isAssetVisible: _isAssetVisible,
          assetReferenceDate: state.assetReferenceDate,
          totalAssets: state.getFilteredNetAssets(),
          onToggleVisibility: () {
            setState(() => _isAssetVisible = !_isAssetVisible);
            SharedPreferences.getInstance().then((prefs) => prefs.setBool('isAssetVisible', _isAssetVisible));
          },
          onChangeDate: (date) => state.setAssetReferenceDate(date),
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
