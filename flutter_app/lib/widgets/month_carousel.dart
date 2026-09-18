import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';

class MonthCarousel extends StatefulWidget {
  final AppState state;
  const MonthCarousel({super.key, required this.state});

  @override
  State<MonthCarousel> createState() => MonthCarouselState();
}

class MonthCarouselState extends State<MonthCarousel> {
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _activeMonthKey = GlobalKey();
  bool _shouldScrollToLeft = true;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void scrollToActive() {
    _shouldScrollToLeft = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final now = DateTime.now();
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
      if (isActive) targetOffset = currentAccumulatedWidth;
      currentAccumulatedWidth += 54.0;
      items.add(_monthPill(m, isActive, state, key: isActive ? _activeMonthKey : null));
    }

    if (_shouldScrollToLeft) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          if (_activeMonthKey.currentContext != null) {
            Scrollable.ensureVisible(_activeMonthKey.currentContext!, alignment: 0.0);
          } else {
            _scrollCtrl.jumpTo(targetOffset);
          }
        }
        _shouldScrollToLeft = false;
      });
    }

    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 12, right: 200),
        child: Row(children: items),
      ),
    );
  }

  Widget _monthPill(DateTime m, bool isActive, AppState state, {Key? key}) {
    return GestureDetector(
      key: key,
      onTap: () {
        _shouldScrollToLeft = false;
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
                color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              )),
        ),
      ),
    );
  }
}
