import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/transaction.dart';
import '../models/category_info.dart';
import '../utils/helpers.dart';

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
  bool _isFixed = false;

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
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF1F5F9),
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
                  child: Row(children: [_typeTab('income', '수입'), _typeTab('expense', '지출')]),
                ),
                const SizedBox(height: 16),
                _label('금액'),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.text,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]'))],
                  style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.w700),
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
                    _amountBtn('+100만', 1000000),
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
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 8),
                        Text(_dateStr, style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A))),
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
                          color: isSelected ? c.color.withOpacity(0.15) : const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? c.color.withOpacity(0.4) : const Color(0xFFFFFFFF)),
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
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isFixed,
                        onChanged: (v) => setState(() => _isFixed = v ?? false),
                        activeColor: const Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('매달 고정 지출', style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 16),
                _label('결제수단'),
                DropdownButtonFormField<String>(
                  value: _accountId,
                  dropdownColor: const Color(0xFFFFFFFF),
                  style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A)),
                  decoration: _inputDecoration('결제수단 선택'),
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
                  style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A)),
                  decoration: _inputDecoration('메모를 입력하세요...'),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
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
            color: isActive ? const Color(0xFF4F46E5).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive ? Border.all(color: const Color(0xFF4F46E5).withOpacity(0.4)) : Border.all(color: Colors.transparent),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.notoSansKr(
                  color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
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
          color: const Color(0xFFFFFFFF),
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
        hintStyle: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8)),
        filled: true, fillColor: const Color(0xFFFFFFFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('결제수단을 선택해주세요', style: GoogleFonts.notoSansKr())));
      return;
    }

    final baseId = 'tx_${DateTime.now().millisecondsSinceEpoch}';

    if (_isFixed) {
      final parts = _dateStr.split('-');
      int y = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      int d = int.parse(parts[2]);
      
      List<Transaction> txs = [];
      for (int i = 0; i < 60; i++) {
        int curM = m + i;
        int curY = y + ((curM - 1) ~/ 12);
        curM = ((curM - 1) % 12) + 1;
        
        int lastDay = DateTime(curY, curM + 1, 0).day;
        int curD = d > lastDay ? lastDay : d;
        
        final dateStr = '$curY-${curM.toString().padLeft(2, '0')}-${curD.toString().padLeft(2, '0')}';
        
        txs.add(Transaction(
          id: '${baseId}_$i',
          date: dateStr, accountId: _accountId!, type: _type,
          amount: amount, category: _category, memo: _memoCtrl.text, payment: '자동',
          isRecurring: true, recurringId: baseId,
        ));
      }
      context.read<AppState>().addTransactions(txs);
    } else {
      context.read<AppState>().addTransaction(Transaction(
        id: baseId,
        date: _dateStr, accountId: _accountId!, type: _type,
        amount: amount, category: _category, memo: _memoCtrl.text, payment: '자동',
      ));
    }
    
    Navigator.pop(context);
  }
}
