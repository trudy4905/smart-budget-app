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
        textTheme: GoogleFonts.notoSansKrTextTheme(
          ThemeData.dark().textTheme,
        ),
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

  @override
  void dispose() {
    _monthScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (!state.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              // Background glow blobs
              Positioned(
                top: -80, left: -80,
                child: _glowBlob(const Color(0xFF6366F1), 250),
              ),
              Positioned(
                bottom: 200, right: -80,
                child: _glowBlob(const Color(0xFF3B82F6), 200),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(state),
                    _buildMonthCarousel(state),
                    _buildSummaryCards(state),
                    Expanded(
                      child: _buildCalendarAndDetail(state),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionModal(context),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add),
        label: Text('항목 추가', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _glowBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 120, spreadRadius: 60)],
      ),
    );
  }

  // ---- Header ----
  Widget _buildHeader(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showMonthPickerDialog(context, state),
            child: Row(
              children: [
                Text(
                  state.currentMonthStr,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6366F1), size: 22),
              ],
            ),
          ),
          const Spacer(),
          // Net asset badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 14, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Text(
                  '₩${formatNumber(state.getNetAssets())}',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Month Carousel ----
  Widget _buildMonthCarousel(AppState state) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 24, 1);
    final end = DateTime(now.year, now.month + 18, 1);

    final months = <DateTime>[];
    var cur = DateTime(start.year, start.month, 1);
    while (!cur.isAfter(end)) {
      months.add(cur);
      cur = DateTime(cur.year, cur.month + 1, 1);
    }

    final activeIdx = months.indexWhere(
      (m) => m.year == state.currentDate.year && m.month == state.currentDate.month,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_monthScrollCtrl.hasClients && activeIdx >= 0) {
        final itemW = 56.0;
        final offset = (activeIdx * itemW) - (MediaQuery.of(context).size.width / 2) + itemW / 2;
        _monthScrollCtrl.animateTo(
          offset.clamp(0.0, _monthScrollCtrl.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    int? lastYear;
    final items = <Widget>[];
    for (final m in months) {
      if (lastYear != null && m.year != lastYear) {
        items.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('${m.year}', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
        ));
      }
      lastYear = m.year;
      final isActive = m.year == state.currentDate.year && m.month == state.currentDate.month;
      items.add(_monthPill(m, isActive, state));
    }

    return SizedBox(
      height: 40,
      child: ListView(
        controller: _monthScrollCtrl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: items,
      ),
    );
  }

  Widget _monthPill(DateTime m, bool isActive, AppState state) {
    return GestureDetector(
      onTap: () {
        state.setCurrentDate(m);
        state.setSelectedDate(
          '${m.year}-${m.month.toString().padLeft(2, '0')}-01',
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF6366F1) : const Color(0xFF334155),
          ),
        ),
        child: Text(
          '${m.month}월',
          style: GoogleFonts.notoSansKr(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  // ---- Summary Cards ----
  Widget _buildSummaryCards(AppState state) {
    final summary = state.getMonthlySummary(state.currentDate.year, state.currentDate.month);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _summaryCard('수입', summary['income']!, const Color(0xFF10B981), '💵'),
          const SizedBox(width: 8),
          _summaryCard('현금지출', summary['cash']!, const Color(0xFFF43F5E), '💰'),
          const SizedBox(width: 8),
          _summaryCard('카드', summary['card']!, const Color(0xFFA855F7), '💳'),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, int amount, Color color, String emoji) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$emoji $label', style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF94A3B8))),
            const SizedBox(height: 4),
            Text(
              '₩${formatNumber(amount)}',
              style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w700, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
    final startDow = firstDay.weekday % 7; // 0=Sun
    final totalDays = DateTime(year, month + 1, 0).day;
    final prevMonthDays = DateTime(year, month, 0).day;
    final todayStr = _todayStr();

    // Total cells needed (5 or 6 rows)
    final totalCells = startDow + totalDays;
    final rows = (totalCells / 7).ceil();

    final dayHeaders = ['일', '월', '화', '수', '목', '금', '토'];

    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Day-of-week headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: List.generate(7, (i) => Expanded(
                child: Center(
                  child: Text(
                    dayHeaders[i],
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: i == 0
                          ? const Color(0xFFEF4444)
                          : i == 6
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )),
            ),
          ),
          // Calendar cells
          ...List.generate(rows, (row) {
            return Row(
              children: List.generate(7, (col) {
                final cellIdx = row * 7 + col;
                final dayOffset = cellIdx - startDow;

                int dayNum;
                String dateStr;
                bool isOtherMonth;

                if (cellIdx < startDow) {
                  // Previous month
                  dayNum = prevMonthDays - (startDow - cellIdx - 1);
                  final prevMonth = month - 1 <= 0 ? 12 : month - 1;
                  final prevYear = month - 1 <= 0 ? year - 1 : year;
                  dateStr = '$prevYear-${prevMonth.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                  isOtherMonth = true;
                } else if (dayOffset >= totalDays) {
                  // Next month
                  dayNum = dayOffset - totalDays + 1;
                  final nextMonth = month + 1 > 12 ? 1 : month + 1;
                  final nextYear = month + 1 > 12 ? year + 1 : year;
                  dateStr = '$nextYear-${nextMonth.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
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
                    dayNum: dayNum,
                    dateStr: dateStr,
                    isOtherMonth: isOtherMonth,
                    isToday: isToday,
                    isSelected: isSelected,
                    txs: txs,
                    accounts: state.accounts,
                    onTap: () {
                      state.setSelectedDate(dateStr);
                      // If tapping other month, navigate there
                      if (isOtherMonth) {
                        final parts = dateStr.split('-');
                        if (parts.length == 3) {
                          final y = int.parse(parts[0]);
                          final m = int.parse(parts[1]);
                          state.setCurrentDate(DateTime(y, m, 1));
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
    required int dayNum,
    required String dateStr,
    required bool isOtherMonth,
    required bool isToday,
    required bool isSelected,
    required List<Transaction> txs,
    required List<Account> accounts,
    required VoidCallback onTap,
  }) {
    final textColor = isOtherMonth
        ? const Color(0xFF334155)
        : isSelected
            ? Colors.white
            : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withOpacity(0.25)
              : isToday
                  ? const Color(0xFF1E293B)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFF6366F1), width: 1.5)
              : isToday
                  ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.4))
                  : null,
        ),
        child: Column(
          children: [
            const SizedBox(height: 4),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isToday && !isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$dayNum',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isOtherMonth
                        ? const Color(0xFF334155)
                        : isToday
                            ? Colors.white
                            : textColor,
                  ),
                ),
              ),
            ),
            // Transaction chips
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
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '+$overflow',
              style: GoogleFonts.notoSansKr(fontSize: 8, color: const Color(0xFF94A3B8)),
            ),
          ),
      ],
    );
  }

  Widget _buildChip(Transaction t, List<Account> accounts) {
    final acc = accounts.firstWhereOrNull((a) => a.id == t.accountId);
    final isCard = acc != null && acc.isCredit;
    final isIncome = t.type == 'income';

    Color chipColor;
    String icon;
    String text;

    if (isIncome) {
      chipColor = const Color(0xFF10B981);
      icon = '💵';
      text = '+${formatCompactNumber(t.amount)}';
    } else if (isCard) {
      chipColor = const Color(0xFFA855F7);
      icon = '💳';
      text = t.memo.isNotEmpty ? t.memo.split(' ').first : t.category;
    } else {
      chipColor = const Color(0xFFF43F5E);
      icon = '💰';
      text = t.amount > 0 ? '-${formatCompactNumber(t.amount)}' : (t.memo.isNotEmpty ? t.memo : t.category);
    }

    return Container(
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 7)),
          const SizedBox(width: 1),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.notoSansKr(fontSize: 8, color: chipColor, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
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
        // Detail header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                titleText,
                style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const Spacer(),
              Text(
                '지출 ₩${formatNumber(dailyExpense)}',
                style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFFF43F5E)),
              ),
            ],
          ),
        ),
        // Transaction list
        Expanded(
          child: txs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_outlined, color: Color(0xFF334155), size: 40),
                      const SizedBox(height: 8),
                      Text(
                        '등록된 내역이 없습니다',
                        style: GoogleFonts.notoSansKr(color: const Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+ 항목 추가를 눌러 기록해보세요',
                        style: GoogleFonts.notoSansKr(color: const Color(0xFF475569), fontSize: 11),
                      ),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: catInfo.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(catInfo.emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.memo.isNotEmpty ? tx.memo : tx.category,
                  style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '$accLabel • ${tx.category} • ${tx.payment.isNotEmpty ? tx.payment : '미지정'}',
                  style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '-' : '+'}₩${formatNumber(tx.amount)}',
                style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w700, color: amountColor),
              ),
              IconButton(
                onPressed: () => _confirmDelete(tx.id, state),
                icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFF64748B)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
            onPressed: () {
              state.deleteTransaction(id);
              Navigator.pop(context);
            },
            child: Text('삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFFF43F5E))),
          ),
        ],
      ),
    );
  }

  // ---- Month picker dialog ----
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
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () => setDialogState(() => displayYear--),
              ),
              Text('$displayYear년', style: GoogleFonts.notoSansKr(color: Colors.white, fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () => setDialogState(() => displayYear++),
              ),
            ],
          ),
          content: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: List.generate(12, (i) {
              final isActive = displayYear == state.currentDate.year && i + 1 == state.currentDate.month;
              return GestureDetector(
                onTap: () {
                  state.setCurrentDate(DateTime(displayYear, i + 1, 1));
                  state.setSelectedDate('$displayYear-${(i + 1).toString().padLeft(2, '0')}-01');
                  Navigator.pop(ctx);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}월',
                      style: GoogleFonts.notoSansKr(
                        color: isActive ? Colors.white : const Color(0xFF94A3B8),
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ---- Add Transaction Modal ----
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
    if (s.accounts.isNotEmpty) {
      _accountId = s.accounts.first.id;
    }
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
    if (!cats.any((c) => c.name == _category)) {
      _category = cats.first.name;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('항목 추가', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
            // Type toggle
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _typeTab('expense', '지출'),
                  _typeTab('income', '수입'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Amount
            _label('금액'),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              decoration: _inputDecoration('₩ 0').copyWith(
                prefixText: '₩ ',
                prefixStyle: const TextStyle(color: Color(0xFF6366F1), fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            // Date
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
            // Category
            _label('카테고리'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
            // Account
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
            // Payment
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
            // Memo
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
            child: Text(
              label,
              style: GoogleFonts.notoSansKr(
                color: isActive ? Colors.white : const Color(0xFF64748B),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
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
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1)),
        ),
      );

  Future<void> _pickDate() async {
    final parts = _dateStr.split('-');
    final init = parts.length == 3
        ? DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]))
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF6366F1), surface: Color(0xFF1E293B)),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('계좌를 선택해주세요', style: GoogleFonts.notoSansKr())),
      );
      return;
    }
    final tx = Transaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      date: _dateStr,
      accountId: _accountId!,
      type: _type,
      amount: amount,
      category: _category,
      memo: _memoCtrl.text,
      payment: _payment,
    );
    context.read<AppState>().addTransaction(tx);
    Navigator.pop(context);
  }
}
