import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';
import 'package:flutter_app/features/drawer/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter_app/features/drawer/dashboard/views/drawer_side_panel.dart';
import 'package:flutter_app/features/drawer/dashboard/models/dashboard_summary.dart';
import 'package:flutter_app/features/drawer/dashboard/views/widgets/cash_flow_section_ui.dart';

class CashFlowSection extends StatefulWidget {
  const CashFlowSection({super.key});

  @override
  State<CashFlowSection> createState() => _CashFlowSectionState();
}

class _CashFlowSectionState extends State<CashFlowSection> {
  DateTime _drawerCashFlowDate = DateTime.now();
  String _openPanel = '';

  void _toggleSidePanel(String type, BuildContext context, DashboardSummary dash) {
    setState(() {
      _openPanel = type;
    });

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.2),
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: DrawerSidePanel(dash: dash, openPanelType: type),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _openPanel = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UiViewModel, DashboardViewModel>(
      builder: (context, uiVM, dashboardVM, _) {
        final dash = dashboardVM.getDashboardSummary(_drawerCashFlowDate.year, _drawerCashFlowDate.month);

        return CashFlowSectionUI(
          drawerCashFlowDate: _drawerCashFlowDate,
          dash: dash,
          dashboardItemOrder: uiVM.dashboardItemOrder,
          openPanel: _openPanel,
          onToggleSidePanel: _toggleSidePanel,
          onReorder: (oldIndex, newIndex) {
            uiVM.reorderDashboardItems(oldIndex, newIndex);
          },
          onChangeMonth: (delta) {
            setState(() {
              _drawerCashFlowDate = DateTime(_drawerCashFlowDate.year, _drawerCashFlowDate.month + delta, 1);
              _openPanel = '';
            });
          },
        );
      },
    );
  }
}

