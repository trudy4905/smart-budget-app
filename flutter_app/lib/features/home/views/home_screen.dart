import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/core/providers/app_state.dart';
import 'package:flutter_app/features/home/views/widgets/custom_speed_dial.dart';
import 'package:flutter_app/features/drawer/views/app_drawer.dart';
import 'package:flutter_app/features/home/views/widgets/month_carousel.dart';
import 'package:flutter_app/features/home/views/widgets/calendar_grid.dart';
import 'package:flutter_app/features/home/views/widgets/daily_detail.dart';
import 'package:flutter_app/features/transactions/views/add_transaction_screen.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<MonthCarouselState> _carouselKey = GlobalKey<MonthCarouselState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surface,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Consumer<AppState>(
            builder: (context, state, _) {
              if (!state.loaded) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              return SafeArea(
                child: Column(
                  children: [
                    _buildHeader(state),
                    MonthCarousel(
                      key: _carouselKey,
                      currentDate: state.currentDate,
                      onMonthSelected: (month) {
                        state.setCurrentDate(month);
                        state.setSelectedDate('${month.year}-${month.month.toString().padLeft(2, '0')}-01');
                      },
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          CalendarGrid(
                            currentDate: state.currentDate,
                            selectedDateStr: state.selectedDateStr,
                            accounts: state.accounts,
                            getTransactionsForDate: state.getTransactionsForDate,
                            onDateSelected: (dateStr, isOtherMonth) {
                              state.setSelectedDate(dateStr);
                              if (isOtherMonth) {
                                final parts = dateStr.split('-');
                                if (parts.length == 3) {
                                  state.setCurrentDate(DateTime(int.parse(parts[0]), int.parse(parts[1]), 1));
                                }
                              }
                            },
                          ),
                          const Divider(color: AppColors.surface, height: 1),
                          Expanded(
                            child: DailyDetail(
                              selectedDateStr: state.selectedDateStr,
                              transactions: state.getTransactionsForDate(state.selectedDateStr),
                              accounts: state.accounts,
                              getCategoryInfo: state.getCategoryInfo,
                              onDeleteTransaction: state.deleteTransaction,
                              onDeleteRecurringTransactions: state.deleteRecurringTransactions,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: SafeArea(
              child: CustomSpeedDial(
                onSelect: (type) => _showAddTransactionModal(context, initialType: type),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppState state) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Hamburger menu button
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.menu_rounded, color: AppColors.textMain, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Month + year picker trigger
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showMonthPickerDialog(context, state),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.currentMonthStr,
                      style: GoogleFonts.notoSansKr(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 22),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Today button
          GestureDetector(
            onTap: () {
              final today = DateTime.now();
              state.setCurrentDate(today);
              state.setSelectedDate('${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}');
              _carouselKey.currentState?.scrollToActive();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.today_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('${now.day}일',
                      style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthPickerDialog(BuildContext context, AppState state) {
    int displayYear = state.currentDate.year;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left, color: AppColors.textMain), onPressed: () => setDialogState(() => displayYear--)),
              Text('$displayYear년', style: GoogleFonts.notoSansKr(color: AppColors.textMain, fontWeight: FontWeight.w700, fontSize: 18)),
              IconButton(icon: const Icon(Icons.chevron_right, color: AppColors.textMain), onPressed: () => setDialogState(() => displayYear++)),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: List.generate(12, (i) {
                final isActive = displayYear == state.currentDate.year && i + 1 == state.currentDate.month;
                return GestureDetector(
                  onTap: () {
                    state.setCurrentDate(DateTime(displayYear, i + 1, 1));
                    state.setSelectedDate('$displayYear-${(i + 1).toString().padLeft(2, '0')}-01');
                    _carouselKey.currentState?.scrollToActive();
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isActive ? AppColors.primary : AppColors.divider),
                    ),
                    child: Center(
                      child: Text('${i + 1}월',
                          style: GoogleFonts.notoSansKr(
                            color: isActive ? AppColors.textMain : AppColors.textSub,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                            fontSize: 13,
                          )),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTransactionModal(BuildContext context, {String initialType = 'expense'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppState>(),
        child: AddTransactionScreen(initialType: initialType),
      ),
    );
  }
}
