import 'package:flutter/material.dart';
import 'package:flutter_app/features/drawer/views/header/drawer_header.dart';
import 'package:flutter_app/features/drawer/views/footer/drawer_footer.dart';
import 'package:flutter_app/features/drawer/dashboard/views/asset_summary_card.dart';
import 'package:flutter_app/features/drawer/dashboard/views/cash_flow_section.dart';
import 'package:flutter_app/features/drawer/accounts/views/accounts_section.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.86,
      backgroundColor: const Color(0xFFF8FAFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      elevation: 12,
      child: const SafeArea(
        child: Column(
          children: [
            DrawerHeaderWidget(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    AssetSummaryCard(),
                    CashFlowSection(),
                    AccountsSection(),
                    DrawerFooterWidget(),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
