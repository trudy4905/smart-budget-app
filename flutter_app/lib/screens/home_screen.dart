import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/home/custom_speed_dial.dart';
import '../widgets/drawer/app_drawer.dart';
import '../widgets/home/month_carousel.dart';
import '../widgets/home/calendar_grid.dart';
import '../widgets/home/daily_detail.dart';
import 'add_transaction_screen.dart';

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
      backgroundColor: const Color(0xFFFFFFFF),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Consumer<AppState>(
            builder: (context, state, _) {
              if (!state.loaded) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
              }
              return SafeArea(
                child: Column(
                  children: [
                    _buildHeader(state),
                    MonthCarousel(key: _carouselKey, state: state),
                    Expanded(
                      child: Column(
                        children: [
                          CalendarGrid(state: state),
                          const Divider(color: Color(0xFFFFFFFF), height: 1),
                          Expanded(child: DailyDetail(state: state)),
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
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 20),
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
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.currentMonthStr,
                      style: GoogleFonts.notoSansKr(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4F46E5), size: 22),
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
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.today_rounded, size: 16, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 6),
                  Text('${now.day}일',
                      style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
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
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left, color: Color(0xFF0F172A)), onPressed: () => setDialogState(() => displayYear--)),
              Text('$displayYear년', style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18)),
              IconButton(icon: const Icon(Icons.chevron_right, color: Color(0xFF0F172A)), onPressed: () => setDialogState(() => displayYear++)),
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
                      color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Text('${i + 1}월',
                          style: GoogleFonts.notoSansKr(
                            color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
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
