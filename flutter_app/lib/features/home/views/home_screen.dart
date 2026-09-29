import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/drawer/dashboard/view_models/dashboard_view_model.dart';
import 'package:flutter_app/core/providers/ui_view_model.dart';
import 'package:flutter_app/features/drawer/accounts/view_models/account_view_model.dart';
import 'package:flutter_app/features/categories/view_models/category_view_model.dart';
import 'package:flutter_app/features/home/add_transaction/view_models/transaction_view_model.dart';
import 'package:flutter_app/features/home/views/widgets/custom_speed_dial.dart';
import 'package:flutter_app/features/drawer/views/app_drawer.dart';
import 'package:flutter_app/features/home/views/widgets/month_carousel.dart';
import 'package:flutter_app/features/home/views/widgets/calendar_grid.dart';
import 'package:flutter_app/features/home/views/widgets/daily_detail.dart';
import 'package:flutter_app/features/home/add_transaction/views/add_transaction_screen.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<MonthCarouselState> _carouselKey = GlobalKey<MonthCarouselState>();
  late PageController _pageController;
  bool _isPageControllerInitialized = false;

  @override
  void dispose() {
    if (_isPageControllerInitialized) _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surface,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Consumer4<UiViewModel, AccountViewModel, CategoryViewModel, TransactionViewModel>(
            builder: (context, uiVM, accountVM, catVM, txVM, _) {
              final targetIndex = (uiVM.currentDate.year - 2000) * 12 + (uiVM.currentDate.month - 1);
              if (!_isPageControllerInitialized) {
                _pageController = PageController(initialPage: targetIndex);
                _isPageControllerInitialized = true;
              } else if (_pageController.hasClients) {
                if (_pageController.page?.round() != targetIndex) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_pageController.hasClients) {
                      _pageController.animateToPage(
                        targetIndex,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  });
                }
              }
              return SafeArea(
                child: Column(
                  children: [
                    _buildHeader(uiVM),
                    MonthCarousel(
                      key: _carouselKey,
                      currentDate: uiVM.currentDate,
                      onMonthSelected: (month) {
                        uiVM.setCurrentDate(month);
                        uiVM.setSelectedDate('${month.year}-${month.month.toString().padLeft(2, '0')}-01');
                      },
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          final newDate = DateTime(2000 + (index ~/ 12), (index % 12) + 1, 1);
                          if (uiVM.currentDate.year != newDate.year || uiVM.currentDate.month != newDate.month) {
                            uiVM.setCurrentDate(newDate);
                            uiVM.setSelectedDate('${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-01');
                            _carouselKey.currentState?.scrollToActive();
                          }
                        },
                        itemBuilder: (context, index) {
                          final pageDate = DateTime(2000 + (index ~/ 12), (index % 12) + 1, 1);
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: constraints.maxHeight,
                                      child: CalendarGrid(
                                        currentDate: pageDate,
                                        selectedDateStr: uiVM.selectedDateStr,
                                        accounts: accountVM.accounts,
                                        getTransactionsForDate: context.read<DashboardViewModel>().getTransactionsForDate,
                                        getCategoryInfo: catVM.getCategoryInfo,
                                        onDateSelected: (dateStr, isOtherMonth) {
                                          uiVM.setSelectedDate(dateStr);
                                          if (isOtherMonth) {
                                            final parts = dateStr.split('-');
                                            if (parts.length == 3) {
                                              uiVM.setCurrentDate(DateTime(int.parse(parts[0]), int.parse(parts[1]), 1));
                                              _carouselKey.currentState?.scrollToActive();
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                    const Divider(color: AppColors.surface, height: 1),
                                    DailyDetail(
                                      selectedDateStr: uiVM.selectedDateStr,
                                      transactions: context.read<DashboardViewModel>().getTransactionsForDate(uiVM.selectedDateStr),
                                      accounts: accountVM.accounts,
                                      getCategoryInfo: catVM.getCategoryInfo,
                                      onDeleteTransaction: txVM.deleteTransaction,
                                      onDeleteRecurringTransactions: txVM.deleteRecurringTransactions,
                                    ),
                                    SizedBox(height: constraints.maxHeight / 2),
                                  ],
                                ),
                              );
                            },
                          );
                        },
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

  Widget _buildHeader(UiViewModel uiVM) {
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
            onTap: () => _showMonthPickerDialog(context, uiVM),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${uiVM.currentDate.year}년 ${uiVM.currentDate.month}월',
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
              uiVM.setCurrentDate(today);
              uiVM.setSelectedDate('${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}');
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

  void _showMonthPickerDialog(BuildContext context, UiViewModel uiVM) {
    int displayYear = uiVM.currentDate.year;
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
                final isActive = displayYear == uiVM.currentDate.year && i + 1 == uiVM.currentDate.month;
                return GestureDetector(
                  onTap: () {
                    uiVM.setCurrentDate(DateTime(displayYear, i + 1, 1));
                    uiVM.setSelectedDate('$displayYear-${(i + 1).toString().padLeft(2, '0')}-01');
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
      builder: (_) => AddTransactionScreen(initialType: initialType),
    );
  }
}
