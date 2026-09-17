import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category_info.dart';
import '../utils/helpers.dart';


class CustomSpeedDial extends StatefulWidget {
  final Function(String) onSelect;
  const CustomSpeedDial({super.key, required this.onSelect});

  @override
  State<CustomSpeedDial> createState() => _CustomSpeedDialState();
}

class _CustomSpeedDialState extends State<CustomSpeedDial> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }
  
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() => _isOpen = !_isOpen);
  }

  Widget _buildItem(String label, IconData icon, String type) {
    return GestureDetector(
      onTap: () {
        _toggle();
        widget.onSelect(type);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE5EDFA),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF1D4ED8), size: 20),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1D4ED8))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizeTransition(
          sizeFactor: _anim,
          axisAlignment: 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildItem('수입', Icons.download_rounded, 'income'),
              _buildItem('지출', Icons.upload_rounded, 'expense'),
            ],
          ),
        ),
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: const Color(0xFF2563EB),
          elevation: 4,
          shape: const CircleBorder(),
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }
}

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
                _buildMonthCarousel(state),
                Expanded(child: _buildCalendarAndDetail(state)),
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
                      style: GoogleFonts.notoSansKr(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4F46E5), size: 22),
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
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.today_rounded, size: 16, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 6),
                  Text('${now.day}일',
                      style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
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
              style: GoogleFonts.notoSansKr(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
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
      child: SingleChildScrollView(
        controller: _monthScrollCtrl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 12, right: 200),
        child: Row(
          children: items,
        ),
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
          color: isActive ? const Color(0xFFD3E3FD) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.transparent : const Color(0xFFE0E0E0)),
        ),
        child: Center(
          child: Text('${m.month}월',
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? Color(0xFF0F172A) : const Color(0xFF64748B),
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
        const Divider(color: Color(0xFFFFFFFF), height: 1),
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
      color: const Color(0xFFFFFFFF),
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
                        color: i == 0 ? const Color(0xFFD93025) : i == 6 ? const Color(0xFF1A73E8) : const Color(0xFF70757A),
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
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD3E3FD).withOpacity(0.5) : Colors.transparent,
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: Column(
          children: [
            const SizedBox(height: 4),
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: isToday ? const Color(0xFF1A73E8) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$dayNum',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? const Color(0xFFFFFFFF) : (isOtherMonth ? const Color(0xFFD4D4D4) : const Color(0xFF3C4043)),
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
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(3)),
            child: Text('+$overflow', style: GoogleFonts.notoSansKr(fontSize: 8, color: const Color(0xFF64748B))),
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
      chipColor = const Color(0xFF059669); icon = '💵';
      text = '+${formatCompactNumber(t.amount)}';
    } else if (isCard) {
      chipColor = const Color(0xFF9333EA); icon = '💳';
      text = t.memo.isNotEmpty ? t.memo.split(' ').first : t.category;
    } else {
      chipColor = const Color(0xFFE11D48); icon = '💰';
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
              Text(titleText, style: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const Spacer(),
              Text('지출 ₩${formatNumber(dailyExpense)}', style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFFE11D48))),
            ],
          ),
        ),
        Expanded(
          child: txs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_outlined, color: Color(0xFFE2E8F0), size: 40),
                      const SizedBox(height: 8),
                      Text('등록된 내역이 없습니다', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8), fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('+ 항목 추가를 눌러 기록해보세요', style: GoogleFonts.notoSansKr(color: const Color(0xFFF8FAFC), fontSize: 11)),
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
    final amountColor = isExpense ? const Color(0xFFE11D48) : const Color(0xFF059669);
    final accLabel = acc != null
        ? (acc.isCredit ? '💳[신용] ${acc.name}' : acc.isDebit ? '💳[체크] ${acc.name}' : '🏦 ${acc.name}')
        : '미지정 계좌';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    style: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('$accLabel • ${tx.category} • ${tx.payment.isNotEmpty ? tx.payment : '미지정'}',
                    style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF94A3B8)),
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
                  child: Icon(Icons.delete_outline, size: 16, color: Color(0xFF94A3B8)),
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
        backgroundColor: const Color(0xFFFFFFFF),
        title: Text('삭제', style: GoogleFonts.notoSansKr(color: Color(0xFF0F172A))),
        content: Text('해당 내역을 삭제하시겠습니까?', style: GoogleFonts.notoSansKr(color: const Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8)))),
          TextButton(
            onPressed: () { state.deleteTransaction(id); Navigator.pop(context); },
            child: Text('삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFFE11D48))),
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
              Text('$displayYear년', style: GoogleFonts.notoSansKr(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 18)),
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
                    _shouldScrollMonthToLeft = true;
                    state.setCurrentDate(DateTime(displayYear, i + 1, 1));
                    state.setSelectedDate('$displayYear-${(i + 1).toString().padLeft(2, '0')}-01');
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
                            color: isActive ? Color(0xFF0F172A) : const Color(0xFF64748B),
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
          backgroundColor: const Color(0xFFF1F5F9),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // ---- Header ----
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFFFFFFF))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.account_balance_wallet, color: Color(0xFF64748B), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Smart Budget',
                              style: GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          Text(state.currentMonthStr,
                              style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8))),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                      ),
                    ],
                  ),
                ),

                // ---- 자산 ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('자산', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Builder(
                    builder: (context) {
                      int totalAssets = 0;
                      for (final acc in state.accounts) {
                        if (acc.isBank) {
                          int bal = acc.initialBalance;
                          for (final t in state.transactions) {
                            if (t.accountId != acc.id) continue;
                            if (t.type == 'income') bal += t.amount;
                            if (t.type == 'expense') bal -= t.amount;
                          }
                          totalAssets += bal;
                        }
                      }
                      return Text('₩${formatNumber(totalAssets)}', style: GoogleFonts.notoSansKr(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)));
                    }
                  ),
                ),
                const SizedBox(height: 8),

                // ---- 요약 (Filter Menu) ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('요약', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                ),
                _drawerFilterItem(context, state, 'all', '전체', Icons.public, null, summary['income']! - summary['total']!),
                _drawerFilterItem(context, state, 'income', '수입', Icons.attach_money, null, summary['income']!),
                _drawerFilterItem(context, state, 'cash', '현금 지출', Icons.money, '(현금/체크/지난달 카드)', summary['cash']!),
                _drawerFilterItem(context, state, 'card', '카드 지출', Icons.credit_card, '(다음달 예정)', summary['card']!),

                const Divider(color: Color(0xFFFFFFFF), height: 24),

                // ---- 목록 선택 ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Text('등록 계좌/카드', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          _showAddAccountDialog(context, state);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 12, color: Color(0xFF4F46E5)),
                              const SizedBox(width: 4),
                              Text('계좌/카드 추가', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF4F46E5))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
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
                        icon: acc.isCredit ? Icons.credit_card : acc.isDebit ? Icons.credit_card : Icons.account_balance,
                        label: acc.name,
                        subLabel: acc.isCredit ? '[신용]' : acc.isDebit ? '[체크]' : '[통장] ${acc.bank}',
                        color: hexToColor(acc.color),
                        amount: amount,
                        isAll: false,
                        onAction: (action) {
                          if (action == 'edit') {
                            _showAddAccountDialog(context, state, editAccount: acc);
                          } else if (action == 'delete') {
                            _showDeleteConfirmation(context, state, acc);
                          }
                        },
                      );
                    }),
                  ],
                ),
              ],
            ),
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

  Widget _drawerFilterItem(BuildContext context, AppState state, String filter, String label, IconData icon, String? sub, int amount) {
    final isActive = state.drawerFilter == filter;
    final isPositive = amount >= 0;
    final amountColor = filter == 'income'
        ? const Color(0xFF059669)
        : filter == 'all'
            ? (isPositive ? const Color(0xFF059669) : const Color(0xFFE11D48))
            : const Color(0xFFE11D48);
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
          color: isActive ? const Color(0xFF4F46E5).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: const Color(0xFF4F46E5).withOpacity(0.4)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? const Color(0xFF4F46E5) : Color(0xFF0F172A),
                      )),
                  if (sub != null)
                    Text(sub, style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF94A3B8))),
                ],
              ),
            ),
            Text(amountStr,
                style: GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.w700, color: amountColor)),
            if (isActive) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_rounded, size: 14, color: Color(0xFF4F46E5)),
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
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
    required int? amount,
    required bool isAll,
    Function(String)? onAction,
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
            final next = state.accounts.map((e) => e.id).where((x) => x != id).toList();
            state.setSelectedAccountIds(next);
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
                border: Border.all(color: isChecked ? color : const Color(0xFFE2E8F0), width: 2),
              ),
              child: isChecked ? const Icon(Icons.check, size: 12, color: Color(0xFF0F172A)) : null,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        color: isChecked ? Color(0xFF0F172A) : const Color(0xFF64748B),
                        fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                      )),
                  Text(subLabel, style: GoogleFonts.notoSansKr(fontSize: 10, color: const Color(0xFF94A3B8))),
                ],
              ),
            ),
            if (amount != null)
              Text(
                amount >= 0 ? '₩${formatNumber(amount)}' : '-₩${formatNumber(amount.abs())}',
                style: GoogleFonts.notoSansKr(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: amount >= 0 ? const Color(0xFF059669) : const Color(0xFFE11D48),
                ),
              ),
            if (onAction != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: Color(0xFF94A3B8)),
                color: const Color(0xFFFFFFFF),
                onSelected: onAction,
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'edit', child: Text('수정', style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFF0F172A)))),
                  PopupMenuItem(value: 'delete', child: Text('삭제', style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFFE11D48)))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppState state, Account acc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        title: Text('계좌 삭제', style: GoogleFonts.notoSansKr(color: Color(0xFF0F172A))),
        content: Text('${acc.name}을(를) 삭제하시겠습니까?', style: GoogleFonts.notoSansKr(color: const Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소', style: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8)))),
          TextButton(
            onPressed: () { state.deleteAccount(acc.id); Navigator.pop(context); },
            child: Text('삭제', style: GoogleFonts.notoSansKr(color: const Color(0xFFE11D48))),
          ),
        ],
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, AppState state, {Account? editAccount}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: AddAccountSheet(editAccount: editAccount),
      ),
    );
  }
}

// ============================================================
// ADD ACCOUNT SHEET
// ============================================================
class AddAccountSheet extends StatefulWidget {
  final Account? editAccount;
  const AddAccountSheet({super.key, this.editAccount});

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  String _type = 'bank'; // 'bank', 'credit', 'debit'
  String _bank = '신한은행';
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  int _paymentDay = 25;
  String? _linkedBankId;
  String _color = '#6366f1';

  final _banks = ['신한은행', 'KB국민은행', '우리은행', '하나은행', 'NH농협은행', '기업은행', '토스뱅크', '카카오뱅크', '케이뱅크', '현금/기타'];
  final _cards = ['신한카드', 'KB국민카드', '삼성카드', '현대카드', '롯데카드', '하나카드', '우리카드', 'NH농협카드', 'BC카드', '카카오페이카드', '토스카드'];
  final _colors = ['#6366f1', '#3b82f6', '#10b981', '#ec4899', '#f59e0b', '#8b5cf6'];

  @override
  void initState() {
    super.initState();
    if (widget.editAccount != null) {
      final acc = widget.editAccount!;
      _type = acc.cardKind ?? 'bank';
      _bank = acc.bank;
      _nameCtrl.text = acc.name;
      _balanceCtrl.text = formatNumber(acc.initialBalance);
      _paymentDay = acc.paymentDay ?? 25;
      _linkedBankId = acc.linkedBankAccountId;
      _color = acc.color;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bankList = _type == 'bank' ? _banks : _cards;
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
                Text('계좌/카드 추가', style: GoogleFonts.notoSansKr(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Color(0xFF94A3B8))),
              ],
            ),
            const SizedBox(height: 16),
            // Type toggle
            Container(
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
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
            Text(_type == 'bank' ? '은행' : '카드사', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
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
                        color: isActive ? const Color(0xFF475569) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isActive ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                      ),
                      child: Center(child: Text(b, style: GoogleFonts.notoSansKr(fontSize: 11, color: isActive ? const Color(0xFFFFFFFF) : const Color(0xFF64748B)))),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            // Name
            Text('별칭', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              style: GoogleFonts.notoSansKr(color: Color(0xFF0F172A)),
              decoration: _inputDec(_type == 'bank' ? '예: 주거래 통장' : '예: 신한 쏠 신용카드'),
            ),
            if (_type == 'bank') ...[
              const SizedBox(height: 14),
              Text('초기 잔액', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
              const SizedBox(height: 6),
              TextField(
                controller: _balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                style: GoogleFonts.notoSansKr(color: Color(0xFF0F172A)),
                decoration: _inputDec('예: 1,500,000'),
                onChanged: (value) {
                  String text = value.replaceAll(',', '');
                  if (text.isEmpty || text == '-') return;
                  final number = int.tryParse(text);
                  if (number != null) {
                    final formatted = formatNumber(number);
                    _balanceCtrl.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
              ),
            ],
            if (_type == 'credit') ...[
              const SizedBox(height: 14),
              Text('결제일', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
              const SizedBox(height: 6),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.notoSansKr(color: Color(0xFF0F172A)),
                      decoration: _inputDec('25'),
                      onChanged: (v) => _paymentDay = int.tryParse(v) ?? 25,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('일', style: GoogleFonts.notoSansKr(color: Color(0xFF0F172A))),
                ],
              ),
            ],
            if ((_type == 'credit' || _type == 'debit') && bankAccounts.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(_type == 'debit' ? '연결 통장' : '결제 출금 통장', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _linkedBankId,
                dropdownColor: const Color(0xFFFFFFFF),
                style: GoogleFonts.notoSansKr(color: Color(0xFF0F172A)),
                decoration: _inputDec('선택 안 함'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('선택 안 함')),
                  ...bankAccounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                ],
                onChanged: (v) => setState(() => _linkedBankId = v),
              ),
            ],
            const SizedBox(height: 14),
            Text('테마 색상', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
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
                      border: isActive ? Border.all(color: Color(0xFF0F172A), width: 2.5) : null,
                    ),
                    child: isActive ? const Icon(Icons.check, size: 14, color: Color(0xFF0F172A)) : null,
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
                  backgroundColor: const Color(0xFF475569),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('저장하기', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: const Color(0xFFFFFFFF), fontSize: 15)),
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
        onTap: () => setState(() { _type = type; _bank = type == 'bank' ? _banks.first : _cards.first; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF475569) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.notoSansKr(
                  fontSize: 11, color: isActive ? const Color(0xFFFFFFFF) : const Color(0xFF94A3B8),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                )),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.notoSansKr(color: const Color(0xFFF8FAFC)),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('별칭을 입력해주세요', style: GoogleFonts.notoSansKr())));
      return;
    }
    final acc = Account(
      id: widget.editAccount?.id ?? 'acc_${DateTime.now().millisecondsSinceEpoch}',
      type: _type == 'bank' ? 'bank' : 'card',
      name: name,
      bank: _bank,
      color: _color,
      cardKind: _type == 'bank' ? null : _type,
      initialBalance: _type == 'bank' ? (int.tryParse(_balanceCtrl.text.replaceAll(',', '')) ?? 0) : 0,
      paymentDay: _type == 'credit' ? _paymentDay : null,
      linkedBankAccountId: _linkedBankId,
    );
    
    if (widget.editAccount != null) {
      context.read<AppState>().updateAccount(acc);
    } else {
      context.read<AppState>().addAccount(acc);
    }
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.editAccount != null ? '$name이(가) 수정되었습니다' : '$name이(가) 추가되었습니다', style: GoogleFonts.notoSansKr()),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }
}

// ============================================================
// ADD TRANSACTION SCREEN
// ============================================================
class AddTransactionScreen extends StatefulWidget {
  final String initialType;
  const AddTransactionScreen({super.key, this.initialType = 'expense'});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late String _type;
  String _category = '식당';
  String? _accountId;
  final _amountCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  late String _dateStr;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
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

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFFFFF),
            title: Text('항목 추가', style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
            leading: IconButton(icon: const Icon(Icons.close, color: Color(0xFF0F172A)), onPressed: () => Navigator.pop(context)),
            actions: [
              TextButton(
                onPressed: _save,
                child: Text('저장', style: GoogleFonts.notoSansKr(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ],
          ),
          body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [_typeTab('expense', '지출'), _typeTab('income', '수입')]),
            ),
            const SizedBox(height: 16),
            _label('금액'),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: false),
              style: GoogleFonts.notoSansKr(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.w700),
              decoration: _inputDecoration('0').copyWith(
                prefixText: '₩ ',
                prefixStyle: const TextStyle(color: Color(0xFF475569), fontSize: 20, fontWeight: FontWeight.w700),
              ),
              onChanged: (value) {
                String text = value.replaceAll(',', '');
                if (text.isEmpty || text == '-') return;
                final number = int.tryParse(text);
                if (number != null) {
                  final formatted = formatNumber(number);
                  _amountCtrl.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _amountBtn('+1천', 1000),
                _amountBtn('+1만', 10000),
                _amountBtn('+5만', 50000),
                _amountBtn('+10만', 100000),
                _amountBtn('C', 0),
              ],
            ),
            const SizedBox(height: 16),
            _label('날짜'),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 8),
                    Text(_dateStr, style: GoogleFonts.notoSansKr(color: Color(0xFF0F172A))),
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
                      color: isSelected ? c.color.withOpacity(0.2) : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? c.color : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.emoji),
                        const SizedBox(width: 6),
                        Text(c.name, style: GoogleFonts.notoSansKr(color: isSelected ? c.color : const Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _label(_type == 'expense' ? '계좌/카드' : '계좌'),
            DropdownButtonFormField<String>(
              value: _accountId,
              dropdownColor: const Color(0xFFFFFFFF),
              style: GoogleFonts.notoSansKr(color: Color(0xFF0F172A)),
              decoration: _inputDecoration('계좌 선택'),
              items: state.accounts.where((a) => _type == 'income' ? a.isBank : true).map((a) {
                final icon = a.isCredit ? '💳[신용]' : a.isDebit ? '💳[체크]' : '🏦';
                return DropdownMenuItem(value: a.id, child: Text('$icon ${a.name}'));
              }).toList(),
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 16),
            _label('메모'),
            TextField(
              controller: _memoCtrl,
              style: GoogleFonts.notoSansKr(color: Color(0xFF0F172A)),
              decoration: _inputDecoration('메모를 입력하세요...'),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    )));
  }

  Widget _typeTab(String type, String label) {
    final isActive = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          final s = context.read<AppState>();
          if (type == 'income' && _accountId != null) {
            final acc = s.accounts.firstWhereOrNull((a) => a.id == _accountId);
            if (acc != null && !acc.isBank) {
              _accountId = s.accounts.firstWhereOrNull((a) => a.isBank)?.id;
            }
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF475569) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.notoSansKr(
                  color: isActive ? const Color(0xFFFFFFFF) : const Color(0xFF94A3B8),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                )),
          ),
        ),
      ),
    );
  }

  Widget _amountBtn(String label, int addVal) {
    return GestureDetector(
      onTap: () {
        if (addVal == 0) {
          _amountCtrl.clear();
        } else {
          int current = int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
          current += addVal;
          final formatted = formatNumber(current);
          _amountCtrl.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF475569), fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.notoSansKr(fontSize: 12, color: const Color(0xFF64748B))),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.notoSansKr(color: const Color(0xFFF8FAFC)),
        filled: true, fillColor: const Color(0xFFFFFFFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
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
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF4F46E5), surface: Color(0xFFFFFFFF))),
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
      amount: amount, category: _category, memo: _memoCtrl.text, payment: '자동',
    ));
    Navigator.pop(context);
  }
}
