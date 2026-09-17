import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const SmartBudgetApp(),
    ),
  );
}

// ============================================================
// APP ROOT
// ============================================================
class SmartBudgetApp extends StatelessWidget {
  const SmartBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Budget',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF6366F1),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF3B82F6),
          surface: Color(0xFF1E293B),
        ),
        textTheme: GoogleFonts.notoSansKrTextTheme(ThemeData.dark().textTheme),
        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF0F172A)),
      ),
      home: const HomeScreen(),
    );
  }
}

// ============================================================
// HOME SCREEN (Calendar-first)
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _monthScrollCtrl = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _activeMonthKey = GlobalKey();
  bool _shouldScrollMonthToLeft = true;

  @override
  void dispose() {
    _monthScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0F172A),
      drawer: const AppDrawer(),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (!state.loaded) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }
          return Stack(
            children: [
              Positioned(top: -80, left: -80, child: _glowBlob(const Color(0xFF6366F1), 250)),
              Positioned(bottom: 200, right: -80, child: _glowBlob(const Color(0xFF3B82F6), 200)),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(state),
                    _buildMonthCarousel(state),
                    Expanded(child: _buildCalendarAndDetail(state)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionModal(context),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _glowBlob(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 120, spreadRadius: 60)],
      ),
    );
  }

  // ---- Header ----
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
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
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
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.currentMonthStr,
                      style: GoogleFonts.notoSansKr(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6366F1), size: 22),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Today button (displays today's day number e.g. 17일, jumps calendar to today and aligns month to left when clicked)
          GestureDetector(
            onTap: () {
              _shouldScrollMonthToLeft = true;
              final today = DateTime.now();
              state.setCurrentDate(today);
              state.setSelectedDate('${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.today_rounded, size: 16, color: Color(0xFF6366F1)),
                  const SizedBox(width: 6),
                  Text('${now.day}일',
                      style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Month Carousel ----
  Widget _buildMonthCarousel(AppState state) {
    final now = DateTime.now();
    // Allow past months (3 years back) and future months (2 years forward)
    final start = DateTime(now.year - 3, 1, 1);
    final end = DateTime(now.year + 2, 12, 1);

    final months = <DateTime>[];
    var cur = DateTime(start.year, start.month, 1);
    while (!cur.isAfter(end)) {
      months.add(cur);
      cur = DateTime(cur.year, cur.month + 1, 1);
    }

    double currentAccumulatedWidth = 0.0;
    double targetOffset = 0.0;
    int? lastYear;

    final items = <Widget>[];
    for (final m in months) {
      if (lastYear != null && m.year != lastYear) {
        items.add(Padding(
          padding: const EdgeInsets.only(left: 8, right: 4, top: 8),
          child: Text('${m.year}년',
              style: GoogleFonts.notoSansKr(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
        ));
        currentAccumulatedWidth += 46.0;
      }
      lastYear = m.year;
      final isActive = m.year == state.currentDate.year && m.month == state.currentDate.month;
      if (isActive) {
        targetOffset = currentAccumulatedWidth;
      }
      currentAccumulatedWidth += 54.0;
      items.add(_monthPill(m, isActive, state, key: isActive ? _activeMonthKey : null));
    }

    // Force active month to far left edge ONLY when requested (e.g. initial start or today button)
    if (_shouldScrollMonthToLeft) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_monthScrollCtrl.hasClients) {
          if (_activeMonthKey.currentContext != null) {
            Scrollable.ensureVisible(
              _activeMonthKey.currentContext!,
              alignment: 0.0,
            );
          } else {
            _monthScrollCtrl.jumpTo(targetOffset);
          }
        }
        _shouldScrollMonthToLeft = false;
      });
    }

    return SizedBox(
      height: 40,
      child: ListView(
        controller: _monthScrollCtrl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 12, right: 200),
        children: items,
      ),
    );
  }

  Widget _monthPill(DateTime m, bool isActive, AppState state, {Key? key}) {
    return GestureDetector(
      key: key,
      onTap: () {
        _shouldScrollMonthToLeft = false;
        state.setCurrentDate(m);
        state.setSelectedDate('${m.year}-${m.month.toString().padLeft(2, '0')}-01');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? const Color(0xFF6366F1) : const Color(0xFF334155)),
        ),
        child: Center(
          child: Text('${m.month}월',
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
              )),
        ),
      ),
    );
  }



  // ---- Calendar + Daily Detail ----
  Widget _buildCalendarAndDetail(AppState state) {
    return Column(
      children: [
        _buildCalendarGrid(state),
        const Divider(color: Color(0xFF1E293B), height: 1),
        Expanded(child: _buildDailyDetail(state)),
      ],
    );
  }

  Widget _buildCalendarGrid(AppState state) {
    final year = state.currentDate.year;
    final month = state.currentDate.month;
    final firstDay = DateTime(year, month, 1);
    final startDow = firstDay.weekday % 7;
    final totalDays = DateTime(year, month + 1, 0).day;
    final prevMonthDays = DateTime(year, month, 0).day;
    final todayStr = _todayStr();
    final rows = ((startDow + totalDays) / 7).ceil();
    final dayHeaders = ['일', '월', '화', '수', '목', '금', '토'];

    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: List.generate(7, (i) => Expanded(
                child: Center(
                  child: Text(dayHeaders[i],
                      style: GoogleFonts.notoSansKr(
                        fontSize: 11,
                        color: i == 0 ? const Color(0xFFEF4444) : i == 6 ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      )),
                ),
              )),
            ),
          ),
          ...List.generate(rows, (row) {
            return Row(
              children: List.generate(7, (col) {
                final cellIdx = row * 7 + col;
                final dayOffset = cellIdx - startDow;

                int dayNum;
                String dateStr;
                bool isOtherMonth;

                if (cellIdx < startDow) {
                  dayNum = prevMonthDays - (startDow - cellIdx - 1);
                  final pm = month - 1 <= 0 ? 12 : month - 1;
                  final py = month - 1 <= 0 ? year - 1 : year;
                  dateStr = '$py-${pm.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                  isOtherMonth = true;
                } else if (dayOffset >= totalDays) {
                  dayNum = dayOffset - totalDays + 1;
                  final nm = month + 1 > 12 ? 1 : month + 1;
                  final ny = month + 1 > 12 ? year + 1 : year;
                  dateStr = '$ny-${nm.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                  isOtherMonth = true;
                } else {
                  dayNum = dayOffset + 1;
                  dateStr = '$year-${month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                  isOtherMonth = false;
                }

                final isToday = dateStr == todayStr;
                final isSelected = dateStr == state.selectedDateStr;
                final txs = state.getTransactionsForDate(dateStr);

                return Expanded(
                  child: _calendarCell(
                    dayNum: dayNum, dateStr: dateStr,
                    isOtherMonth: isOtherMonth, isToday: isToday,
                    isSelected: isSelected, txs: txs,
                    accounts: state.accounts,
                    onTap: () {
                      state.setSelectedDate(dateStr);
                      if (isOtherMonth) {
                        final parts = dateStr.split('-');
                        if (parts.length == 3) {
                          state.setCurrentDate(DateTime(int.parse(parts[0]), int.parse(parts[1]), 1));
                        }
                      }
                    },
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _calendarCell({
    required int dayNum, required String dateStr,
    required bool isOtherMonth, required bool isToday,
    required bool isSelected, required List<Transaction> txs,
    required List<Account> accounts, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.25)
              : isToday ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: const Color(0xFF6366F1), width: 1.5)
              : isToday ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)) : null,
        ),
        child: Column(
          children: [
            const SizedBox(height: 4),
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: isToday && !isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$dayNum',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isOtherMonth ? const Color(0xFF334155) : Colors.white,
                    )),
              ),
            ),
            if (txs.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _buildCellChips(txs, accounts),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCellChips(List<Transaction> txs, List<Account> accounts) {
    final visible = txs.take(2).toList();
    final overflow = txs.length - visible.length;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...visible.map((t) => _buildChip(t, accounts)),
        if (overflow > 0)
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(3)),
            child: Text('+$overflow', style: GoogleFonts.notoSansKr(fontSize: 8, color: const Color(0xFF94A3B8))),
          ),
      ],
    );
  }

  Widget _buildChip(Transaction t, List<Account> accounts) {
    final acc = accounts.firstWhereOrNull((a) => a.id == t.accountId);
    final isIncome = t.type == 'income';
    final isCard = acc != null && acc.isCredit;

    Color chipColor;
    String icon, text;
    if (isIncome) {
      chipColor = const Color(0xFF10B981); icon = '💵';
      text = '+${formatCompactNumber(t.amount)}';
    } else if (isCard) {
      chipColor = const Color(0xFFA855F7); icon = '💳';
      text = t.memo.isNotEmpty ? t.memo.split(' ').first : t.category;
    } else {
      chipColor = const Color(0xFFF43F5E); icon = '💰';
      text = t.amount > 0 ? '-${formatCompactNumber(t.amount)}' : (t.memo.isNotEmpty ? t.memo : t.category);
    }

    return Container(
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(color: chipColor.withOpacity(0.2), borderRadius: BorderRadius.circular(3)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 7)),
          const SizedBox(width: 1),
          Flexible(
            child: Text(text,
                style: GoogleFonts.notoSansKr(fontSize: 8, color: chipColor, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
        ],
      ),
    );
  }

  // ---- Daily Detail ----
  Widget _buildDailyDetail(AppState state) {
    final dateStr = state.selectedDateStr;
    final parts = dateStr.split('-');
    final dateObj = parts.length == 3
        ? DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]))
        : DateTime.now();
    final dayNames = ['일', '월', '화', '수', '목', '금', '토'];
    final titleText = '${dateObj.month}월 ${dateObj.day}일 (${dayNames[dateObj.weekday % 7]})';
    final txs = state.getTransactionsForDate(dateStr);
    final dailyExpense = txs.where((t) => t.type == 'expense').fold(0, (s, t) => s + t.amount);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(titleText, style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              Text('지출 ₩${formatNumber(dailyExpense)}', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFFF43F5E))),
            ],
          ),
        ),
        Expanded(
          child: txs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_outlined, color: Color(0xFF334155), size: 40),
                      const SizedBox(height: 8),
                      Text('등록된 내역이 없습니다', style: GoogleFonts.notoSansKr(color: const Color(0xFF64748B), fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('+ 항목 추가를 눌러 기록해보세요', style: GoogleFonts.notoSansKr(color: const Color(0xFF475569), fontSize: 11)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: txs.length,
                  itemBuilder: (context, i) => _buildTxItem(txs[i], state),
                ),
        ),
      ],
    );
  }

  Widget _buildTxItem(Transaction tx, AppState state) {
    final acc = state.accounts.firstWhereOrNull((a) => a.id == tx.accountId);
    final catInfo = getCategoryInfo(tx.category);
    final isExpense = tx.type == 'expense';
    final amountColor = isExpense ? const Color(0xFFF43F5E) : const Color(0xFF10B981);
    final accLabel = acc != null
        ? (acc.isCredit ? '💳[신용] ${acc.name}' : acc.isDebit ? '💳[체크] ${acc.name}' : '🏦 ${acc.name}')
        : '미지정 계좌';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: catInfo.color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(catInfo.emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.memo.isNotEmpty ? tx.memo : tx.category,
                    style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('$accLabel • ${tx.category} • ${tx.payment.isNotEmpty ? tx.payment : '미지정'}',
                    style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${isExpense ? '-' : '+'}₩${formatNumber(tx.amount)}',
                  style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w700, color: amountColor)),
              GestureDetector(
                onTap: () => _confirmDelete(tx.id, state),
                child: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.delete_outline, size: 16, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('삭제', style: GoogleFonts.notoSansKr(color: Colors.white)),
        content: Text('해당 내역을 삭제하시겠습니까?', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: GoogleFonts.notoSansKr(color: const Color(0xFF64748B)))),
          TextButton(
            onPressed: () { state.deleteTransaction(id); Navigator.pop(context); },
            child: Text('삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFFF43F5E))),
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
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: () => setDialogState(() => displayYear--)),
              Text('$displayYear년', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
              IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white), onPressed: () => setDialogState(() => displayYear++)),
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
                    _shouldScrollMonthToLeft = true;
                    state.setCurrentDate(DateTime(displayYear, i + 1, 1));
                    state.setSelectedDate('$displayYear-${(i + 1).toString().padLeft(2, '0')}-01');
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isActive ? const Color(0xFF6366F1) : const Color(0xFF334155)),
                    ),
                    child: Center(
                      child: Text('${i + 1}월',
                          style: GoogleFonts.notoSansKr(
                            color: isActive ? Colors.white : const Color(0xFF94A3B8),
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

  void _showAddTransactionModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<AppState>(),
          child: const AddTransactionScreen(),
        ),
      ),
    );
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

// ============================================================
// SIDEBAR DRAWER
// ============================================================
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final summary = state.getMonthlySummary(state.currentDate.year, state.currentDate.month);

        return Drawer(
          width: MediaQuery.of(context).size.width * 0.82,
          backgroundColor: const Color(0xFF0F172A),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Header ----
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Smart Budget',
                              style: GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text(state.currentMonthStr,
                              style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                      ),
                    ],
                  ),
                ),

                // ---- 요약 (Filter Menu) ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('요약', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ),
                _drawerFilterItem(context, state, 'all', '🌐 전체', null, summary['income']! - summary['total']!),
                _drawerFilterItem(context, state, 'income', '💵 수입', null, summary['income']!),
                _drawerFilterItem(context, state, 'cash', '💰 현금 지출', '(현금/체크)', summary['cash']!),
                _drawerFilterItem(context, state, 'card', '💳 카드 지출', '(다음달 예정)', summary['card']!),
                _drawerFilterItem(context, state, 'total_expense', '📊 전체 지출', null, summary['total']!),

                const Divider(color: Color(0xFF1E293B), height: 24),

                // ---- 목록 선택 ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Text('목록 선택', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showAddAccountDialog(context, state);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 12, color: Color(0xFF6366F1)),
                              const SizedBox(width: 4),
                              Text('계좌/카드 추가', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF6366F1))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // All accounts checkbox
                _accountCheckItem(
                  context, state,
                  id: 'all',
                  icon: '🌐',
                  label: '전체 (모든 계좌)',
                  subLabel: '${state.accounts.length}개 계좌',
                  color: const Color(0xFF6366F1),
                  amount: null,
                  isAll: true,
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ...state.accounts.map((acc) {
                        int? amount;
                        if (acc.isBank) {
                          int bal = acc.initialBalance;
                          for (final t in state.transactions) {
                            if (t.accountId != acc.id) continue;
                            if (t.type == 'income') bal += t.amount;
                            if (t.type == 'expense') bal -= t.amount;
                          }
                          amount = bal;
                        } else if (acc.isCredit) {
                          amount = -state.getCardBillForMonth(acc.id, state.currentDate.year, state.currentDate.month);
                        }
                        return _accountCheckItem(
                          context, state,
                          id: acc.id,
                          icon: acc.isCredit ? '💳' : acc.isDebit ? '💳' : '🏦',
                          label: acc.name,
                          subLabel: acc.isCredit ? '[신용]' : acc.isDebit ? '[체크]' : '[통장] ${acc.bank}',
                          color: hexToColor(acc.color),
                          amount: amount,
                          isAll: false,
                          onLongPress: () => _showAccountActions(context, state, acc),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statChip(String label, int amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.notoSansKr(fontSize: 9, color: color)),
            const SizedBox(height: 2),
            Text('₩${formatCompactNumber(amount)}',
                style: GoogleFonts.notoSansKr(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _drawerFilterItem(BuildContext context, AppState state, String filter, String label, String? sub, int amount) {
    final isActive = state.drawerFilter == filter;
    final isPositive = amount >= 0;
    final amountColor = filter == 'income'
        ? const Color(0xFF10B981)
        : filter == 'all'
            ? (isPositive ? const Color(0xFF10B981) : const Color(0xFFF43F5E))
            : const Color(0xFFF43F5E);
    final amountStr = filter == 'income' || filter == 'all'
        ? (isPositive ? '+₩${formatCompactNumber(amount)}' : '-₩${formatCompactNumber(amount.abs())}')
        : '-₩${formatCompactNumber(amount)}';

    return GestureDetector(
      onTap: () {
        // 드로어를 닫지 않고 필터만 변경
        state.setDrawerFilter(filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6366F1).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? const Color(0xFF6366F1) : Colors.white,
                      )),
                  if (sub != null)
                    Text(sub, style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF64748B))),
                ],
              ),
            ),
            Text(amountStr,
                style: GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.w700, color: amountColor)),
            if (isActive) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_rounded, size: 14, color: Color(0xFF6366F1)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _accountCheckItem(
    BuildContext context,
    AppState state, {
    required String id,
    required String icon,
    required String label,
    required String subLabel,
    required Color color,
    required int? amount,
    required bool isAll,
    VoidCallback? onLongPress,
  }) {
    final isAllActive = state.selectedAccountIds.contains('all');
    final isChecked = isAll ? isAllActive : (isAllActive || state.selectedAccountIds.contains(id));

    return GestureDetector(
      onTap: () {
        if (isAll) {
          // 전체 체크박스는 토글 가능 (해제하면 아무것도 표시 안됨)
          if (isAllActive) {
            state.setSelectedAccountIds([]); // 전체 해제
          } else {
            state.setSelectedAccountIds(['all']); // 전체 선택
          }
        } else {
          if (state.selectedAccountIds.contains('all')) {
            state.setSelectedAccountIds([id]);
          } else {
            if (state.selectedAccountIds.contains(id)) {
              final next = state.selectedAccountIds.where((x) => x != id).toList();
              state.setSelectedAccountIds(next); // 빈 배열도 허용
            } else {
              final next = [...state.selectedAccountIds, id];
              state.setSelectedAccountIds(next.length == state.accounts.length ? ['all'] : next);
            }
          }
        }
      },
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isChecked ? color.withOpacity(0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Custom checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: isChecked ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isChecked ? color : const Color(0xFF334155), width: 2),
              ),
              child: isChecked ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Text('$icon ', style: const TextStyle(fontSize: 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        color: isChecked ? Colors.white : const Color(0xFF94A3B8),
                        fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                      )),
                  Text(subLabel, style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF64748B))),
                ],
              ),
            ),
            if (amount != null)
              Text(
                amount >= 0 ? '₩${formatNumber(amount)}' : '-₩${formatNumber(amount.abs())}',
                style: GoogleFonts.notoSansKr(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: amount >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                ),
              ),
            if (onLongPress != null)
              GestureDetector(
                onTap: onLongPress,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.more_vert, size: 16, color: Color(0xFF64748B)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAccountActions(BuildContext context, AppState state, Account acc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(acc.name, style: GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text(acc.bank, style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF64748B))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFF43F5E)),
              title: Text('계좌 삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFFF43F5E))),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    title: Text('계좌 삭제', style: GoogleFonts.notoSansKr(color: Colors.white)),
                    content: Text('${acc.name}을(를) 삭제하시겠습니까?', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8))),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: GoogleFonts.notoSansKr(color: const Color(0xFF64748B)))),
                      TextButton(
                        onPressed: () { state.deleteAccount(acc.id); Navigator.pop(context); },
                        child: Text('삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFFF43F5E))),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: const AddAccountSheet(),
      ),
    );
  }
}

// ============================================================
// ADD ACCOUNT SHEET
// ============================================================
class AddAccountSheet extends StatefulWidget {
  const AddAccountSheet({super.key});

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  String _type = 'bank'; // 'bank', 'credit', 'debit'
  String _bank = '신한은행';
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  int _paymentDay = 25;
  String? _linkedBankId;
  String _color = '#6366f1';

  final _banks = ['신한은행', 'KB국민은행', '우리은행', '하나은행', 'NH농협은행', '기업은행', '토스뱅크', '카카오뱅크', '케이뱅크', '현금/기타'];
  final _cards = ['신한카드', 'KB국민카드', '삼성카드', '현대카드', '롯데카드', '하나카드', '우리카드', 'NH농협카드', 'BC카드', '카카오페이카드', '토스카드'];
  final _colors = ['#6366f1', '#3b82f6', '#10b981', '#ec4899', '#f59e0b', '#8b5cf6'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bankList = _type == 'credit' ? _cards : _banks;
    final bankAccounts = state.accounts.where((a) => a.isBank).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('계좌 추가', style: GoogleFonts.notoSansKr(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 16),
            // Type toggle
            Container(
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  _typeTab('bank', '🏦 통장'),
                  _typeTab('credit', '💳 신용카드'),
                  _typeTab('debit', '💳 체크카드'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Bank/card selection
            Text(_type == 'credit' ? '카드사' : '은행', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8))),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: bankList.map((b) {
                  final isActive = _bank == b;
                  return GestureDetector(
                    onTap: () => setState(() => _bank = b),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isActive ? const Color(0xFF6366F1) : const Color(0xFF334155)),
                      ),
                      child: Center(child: Text(b, style: GoogleFonts.notoSansKr(fontSize: 11, color: isActive ? Colors.white : const Color(0xFF94A3B8)))),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            // Name
            Text('별칭', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8))),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              style: GoogleFonts.notoSansKr(color: Colors.white),
              decoration: _inputDec(_type == 'bank' ? '예: 주거래 통장' : '예: 신한 쏠 신용카드'),
            ),
            if (_type == 'bank') ...[
              const SizedBox(height: 14),
              Text('초기 잔액', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 6),
              TextField(
                controller: _balanceCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.notoSansKr(color: Colors.white),
                decoration: _inputDec('예: 1500000'),
              ),
            ],
            if (_type == 'credit') ...[
              const SizedBox(height: 14),
              Text('결제일', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 6),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.notoSansKr(color: Colors.white),
                      decoration: _inputDec('25'),
                      onChanged: (v) => _paymentDay = int.tryParse(v) ?? 25,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('일', style: GoogleFonts.notoSansKr(color: Colors.white)),
                ],
              ),
            ],
            if ((_type == 'credit' || _type == 'debit') && bankAccounts.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(_type == 'debit' ? '연결 통장' : '결제 출금 통장', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _linkedBankId,
                dropdownColor: const Color(0xFF1E293B),
                style: GoogleFonts.notoSansKr(color: Colors.white),
                decoration: _inputDec('선택 안 함'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('선택 안 함')),
                  ...bankAccounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                ],
                onChanged: (v) => setState(() => _linkedBankId = v),
              ),
            ],
            const SizedBox(height: 14),
            Text('테마 색상', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8))),
            const SizedBox(height: 8),
            Row(
              children: _colors.map((c) {
                final isActive = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 32, height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: hexToColor(c),
                      shape: BoxShape.circle,
                      border: isActive ? Border.all(color: Colors.white, width: 2.5) : null,
                    ),
                    child: isActive ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('저장하기', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeTab(String type, String label) {
    final isActive = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _type = type; _bank = type == 'credit' ? _cards.first : _banks.first; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.notoSansKr(
                  fontSize: 11, color: isActive ? Colors.white : const Color(0xFF64748B),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                )),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.notoSansKr(color: const Color(0xFF475569)),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('별칭을 입력해주세요', style: GoogleFonts.notoSansKr())));
      return;
    }
    final acc = Account(
      id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
      type: _type == 'bank' ? 'bank' : 'card',
      name: name,
      bank: _bank,
      color: _color,
      cardKind: _type == 'bank' ? null : _type,
      initialBalance: _type == 'bank' ? (int.tryParse(_balanceCtrl.text) ?? 0) : 0,
      paymentDay: _type == 'credit' ? _paymentDay : null,
      linkedBankAccountId: _linkedBankId,
    );
    context.read<AppState>().addAccount(acc);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name이(가) 추가되었습니다', style: GoogleFonts.notoSansKr()),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }
}

// ============================================================
// ADD TRANSACTION SCREEN
// ============================================================
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _type = 'expense';
  String _category = '식당';
  String? _accountId;
  final _amountCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  String _payment = '계좌이체';
  late String _dateStr;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _dateStr = s.selectedDateStr;
    if (s.accounts.isNotEmpty) _accountId = s.accounts.first.id;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cats = _type == 'expense' ? kExpenseCategories : kIncomeCategories;
    if (!cats.any((c) => c.name == _category)) _category = cats.first.name;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('항목 추가', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('저장', style: GoogleFonts.notoSansKr(color: const Color(0xFF6366F1), fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [_typeTab('expense', '지출'), _typeTab('income', '수입')]),
            ),
            const SizedBox(height: 16),
            _label('금액'),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              decoration: _inputDecoration('0').copyWith(
                prefixText: '₩ ',
                prefixStyle: const TextStyle(color: Color(0xFF6366F1), fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            _label('날짜'),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    Text(_dateStr, style: GoogleFonts.notoSansKr(color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _label('카테고리'),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: cats.map((c) {
                final isSelected = _category == c.name;
                return GestureDetector(
                  onTap: () => setState(() => _category = c.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? c.color.withOpacity(0.2) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? c.color : const Color(0xFF334155)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.emoji),
                        const SizedBox(width: 6),
                        Text(c.name, style: GoogleFonts.notoSansKr(color: isSelected ? c.color : const Color(0xFF94A3B8), fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _label('계좌'),
            DropdownButtonFormField<String>(
              value: _accountId,
              dropdownColor: const Color(0xFF1E293B),
              style: GoogleFonts.notoSansKr(color: Colors.white),
              decoration: _inputDecoration('계좌 선택'),
              items: state.accounts.map((a) {
                final icon = a.isCredit ? '💳[신용]' : a.isDebit ? '💳[체크]' : '🏦';
                return DropdownMenuItem(value: a.id, child: Text('$icon ${a.name}'));
              }).toList(),
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 16),
            _label('결제수단'),
            DropdownButtonFormField<String>(
              value: _payment,
              dropdownColor: const Color(0xFF1E293B),
              style: GoogleFonts.notoSansKr(color: Colors.white),
              decoration: _inputDecoration('결제수단'),
              items: ['계좌이체', '신용카드', '현금', '기타']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _payment = v ?? _payment),
            ),
            const SizedBox(height: 16),
            _label('메모'),
            TextField(
              controller: _memoCtrl,
              style: GoogleFonts.notoSansKr(color: Colors.white),
              decoration: _inputDecoration('메모를 입력하세요...'),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _typeTab(String type, String label) {
    final isActive = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.notoSansKr(
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                )),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF94A3B8))),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.notoSansKr(color: const Color(0xFF475569)),
        filled: true, fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
      );

  Future<void> _pickDate() async {
    final parts = _dateStr.split('-');
    final init = parts.length == 3
        ? DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]))
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: init, firstDate: DateTime(2020), lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF6366F1), surface: Color(0xFF1E293B))),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateStr = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _save() {
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('계좌를 선택해주세요', style: GoogleFonts.notoSansKr())));
      return;
    }
    context.read<AppState>().addTransaction(Transaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      date: _dateStr, accountId: _accountId!, type: _type,
      amount: amount, category: _category, memo: _memoCtrl.text, payment: _payment,
    ));
    Navigator.pop(context);
  }
}
