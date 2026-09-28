import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../../../../providers/app_state.dart';
import '../../../../../view_models/dashboard_view_model.dart';
import 'widgets/expected_asset_card_ui.dart';
class ExpectedAssetCard extends StatelessWidget {
  final DateTime drawerCashFlowDate;
  
  const ExpectedAssetCard({super.key, required this.drawerCashFlowDate});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppState, DashboardViewModel>(
      builder: (context, state, dashboardVM, _) {
        final dash = dashboardVM.getDashboardSummary(drawerCashFlowDate.year, drawerCashFlowDate.month);
        final expectedBalance = state.getExpectedNetAssetAtEnd(drawerCashFlowDate.year, drawerCashFlowDate.month);
        
        return ExpectedAssetCardUi(
          month: drawerCashFlowDate.month,
          expectedBalance: expectedBalance,
          remainingBalance: dash.remaining,
        );
      },
    );
  }
}
