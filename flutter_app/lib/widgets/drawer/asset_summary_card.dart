import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_state.dart';
import '../../utils/helpers.dart';

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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('내 자산 현황', style: GoogleFonts.notoSansKr(fontSize: 14, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() => _isAssetVisible = !_isAssetVisible);
                            SharedPreferences.getInstance().then((prefs) => prefs.setBool('isAssetVisible', _isAssetVisible));
                          },
                          child: Icon(_isAssetVisible ? Icons.visibility : Icons.visibility_off, size: 16, color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: state.assetReferenceDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          state.setAssetReferenceDate(picked);
                        }
                      },
                      child: Row(
                        children: [
                          Text('${state.assetReferenceDate.year.toString().substring(2)}년 ${state.assetReferenceDate.month}월 ${state.assetReferenceDate.day}일 기준', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Builder(
                  builder: (context) {
                    int totalAssets = 0;
                    if (state.selectedAccountIds.contains('all')) {
                      totalAssets = state.getNetAssets();
                    } else {
                      for (final acc in state.accounts) {
                        if (!state.selectedAccountIds.contains(acc.id)) continue;
                        if (acc.isBank) {
                          totalAssets += state.getBankAccountBalance(acc.id);
                        } else if (acc.isCredit) {
                          totalAssets += state.getCreditCardDebt(acc.id);
                        }
                      }
                    }
                    return ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: _isAssetVisible ? 0 : 8, sigmaY: _isAssetVisible ? 0 : 8),
                      child: Text('${formatNumber(totalAssets)}원', style: GoogleFonts.notoSansKr(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), letterSpacing: -0.5)),
                    );
                  }
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
