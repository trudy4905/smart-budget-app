import 'package:flutter/material.dart';
import 'header/drawer_header.dart';
import 'footer/drawer_footer.dart';
import 'sections/assets/asset_summary_card.dart';
import 'sections/cash_flow/cash_flow_section.dart';
import 'sections/accounts/accounts_section.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Column(
          children: [
            const DrawerHeaderWidget(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const AssetSummaryCard(),
                    const CashFlowSection(),
                    const AccountsSection(),
                    const DrawerFooterWidget(),
                    const SizedBox(height: 24),
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
