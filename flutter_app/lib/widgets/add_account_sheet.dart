import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/account.dart';
import '../utils/helpers.dart';

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
  int _billingStartMonth = -1;
  int _billingStartDay = 1;
  int _billingEndMonth = -1;
  int _billingEndDay = 31;
  String? _linkedBankId;
  String _color = '#6366f1';

  final _banks = ['KB국민은행', '신한은행', '우리은행', '하나은행', 'NH농협은행', 'IBK기업은행', '카카오뱅크', '토스뱅크', '케이뱅크', '새마을금고', '우체국'];
  final _cards = ['신한카드', 'KB국민카드', '삼성카드', '현대카드', '롯데카드', '하나카드', '우리카드', 'NH농협카드', 'BC카드', '카카오페이카드', '토스카드'];

  static const Map<String, String> _logoUrls = {
    '신한카드': 'https://static.toss.im/icons/png/4x/icon-bank-shinhan.png',
    'KB국민카드': 'https://static.toss.im/icons/png/4x/icon-bank-kb.png',
    '삼성카드': 'https://static.toss.im/icons/png/4x/icon-bank-samsung.png',
    '현대카드': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/Hyundai_Card.svg/512px-Hyundai_Card.svg.png',
    '롯데카드': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Lotte_Card_logo.svg/512px-Lotte_Card_logo.svg.png',
    '하나카드': 'https://static.toss.im/icons/png/4x/icon-bank-hana.png',
    '우리카드': 'https://static.toss.im/icons/png/4x/icon-bank-woori.png',
    'NH농협카드': 'https://static.toss.im/icons/png/4x/icon-bank-nh.png',
    'BC카드': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d3/BC_Card_logo.svg/512px-BC_Card_logo.svg.png',
    '카카오페이카드': 'https://static.toss.im/icons/png/4x/icon-bank-kakao.png',
    '토스카드': 'https://static.toss.im/icons/png/4x/icon-bank-toss.png',
    'KB국민은행': 'https://static.toss.im/icons/png/4x/icon-bank-kb.png',
    '신한은행': 'https://static.toss.im/icons/png/4x/icon-bank-shinhan.png',
    '우리은행': 'https://static.toss.im/icons/png/4x/icon-bank-woori.png',
    '하나은행': 'https://static.toss.im/icons/png/4x/icon-bank-hana.png',
    'NH농협은행': 'https://static.toss.im/icons/png/4x/icon-bank-nh.png',
    'IBK기업은행': 'https://static.toss.im/icons/png/4x/icon-bank-ibk.png',
    '카카오뱅크': 'https://static.toss.im/icons/png/4x/icon-bank-kakao.png',
    '토스뱅크': 'https://static.toss.im/icons/png/4x/icon-bank-toss.png',
    '케이뱅크': 'https://static.toss.im/icons/png/4x/icon-bank-kbank.png',
    '새마을금고': 'https://static.toss.im/icons/png/4x/icon-bank-mg.png',
    '우체국': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/58/Korea_Post_logo.svg/512px-Korea_Post_logo.svg.png',
  };
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
      _billingStartMonth = acc.billingStartMonth ?? -1;
      _billingStartDay = acc.billingStartDay ?? 1;
      _billingEndMonth = acc.billingEndMonth ?? -1;
      _billingEndDay = acc.billingEndDay ?? 31;
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
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Color(0xFF0F172A))),
                const SizedBox(width: 8),
                Text('계좌/카드 추가', style: GoogleFonts.notoSansKr(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                const Spacer(),
                GestureDetector(
                  onTap: _save,
                  child: Text('저장', style: GoogleFonts.notoSansKr(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Type toggle
            Container(
              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  _typeTab('bank', '통장', Icons.account_balance, const Color(0xFF059669)),
                  _typeTab('credit', '신용카드', Icons.credit_card, const Color(0xFF2563EB)),
                  _typeTab('debit', '체크카드', Icons.credit_score, const Color(0xFFD97706)),
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
                        color: isActive ? const Color(0xFF4F46E5).withOpacity(0.15) : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isActive ? const Color(0xFF4F46E5).withOpacity(0.4) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLogo(b),
                          Text(b, style: GoogleFonts.notoSansKr(fontSize: 11, color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF64748B))),
                        ],
                      ),
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
              style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A)),
              decoration: _inputDec(_type == 'bank' ? '예: 주거래 통장' : '예: 신한 쏠 신용카드'),
            ),
            if (_type == 'bank') ...[
              const SizedBox(height: 14),
              Text('초기 잔액', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
              const SizedBox(height: 6),
              TextField(
                controller: _balanceCtrl,
                keyboardType: TextInputType.text,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]'))],
                style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A)),
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
                      style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A)),
                      decoration: _inputDec('25'),
                      onChanged: (v) => _paymentDay = int.tryParse(v) ?? 25,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('일', style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _autoCalculateBillingPeriod();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('합산일 자동입력', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('합산 시작일', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
              const SizedBox(height: 6),
              Row(
                children: [
                  _monthDropdown(_billingStartMonth, (v) => setState(() => _billingStartMonth = v!)),
                  const SizedBox(width: 8),
                  _dayDropdown(_billingStartDay, (v) => setState(() => _billingStartDay = v!)),
                ],
              ),
              const SizedBox(height: 10),
              Text('합산 종료일', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
              const SizedBox(height: 6),
              Row(
                children: [
                  _monthDropdown(_billingEndMonth, (v) => setState(() => _billingEndMonth = v!)),
                  const SizedBox(width: 8),
                  _dayDropdown(_billingEndDay, (v) => setState(() => _billingEndDay = v!)),
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
                style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A)),
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
                      border: isActive ? Border.all(color: const Color(0xFF0F172A), width: 2.5) : null,
                    ),
                    child: isActive ? const Icon(Icons.check, size: 14, color: Color(0xFF0F172A)) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(String name) {
    final url = _logoUrls[name];
    if (url == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          url,
          width: 14,
          height: 14,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _monthDropdown(int val, ValueChanged<int?> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<int>(
        value: val,
        dropdownColor: const Color(0xFFFFFFFF),
        style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A), fontSize: 13),
        decoration: _inputDec(''),
        items: const [
          DropdownMenuItem(value: -2, child: Text('전전월')),
          DropdownMenuItem(value: -1, child: Text('전월')),
          DropdownMenuItem(value: 0, child: Text('당월')),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _dayDropdown(int val, ValueChanged<int?> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<int>(
        value: val,
        dropdownColor: const Color(0xFFFFFFFF),
        style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A), fontSize: 13),
        decoration: _inputDec(''),
        items: List.generate(31, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text('$d일${d == 31 ? '(말일)' : ''}'))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _typeTab(String type, String label, IconData iconData, Color iconColor) {
    final isActive = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _type = type; _bank = type == 'bank' ? _banks.first : _cards.first; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4F46E5).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive ? Border.all(color: const Color(0xFF4F46E5).withOpacity(0.4)) : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconData, size: 14, color: isActive ? iconColor : const Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(label,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11, color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.notoSansKr(color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  void _autoCalculateBillingPeriod() {
    int gracePeriod = 14;
    if (_bank.contains('삼성') || _bank.contains('하나') || _bank.contains('비씨') || _bank.contains('BC')) {
      gracePeriod = 13;
    } else if (_bank.contains('현대')) {
      gracePeriod = 12;
    } else if (_bank.contains('기업') || _bank.contains('IBK')) {
      gracePeriod = 15;
    }

    int endDate = _paymentDay - gracePeriod;
    int endMonthOffset = 0;
    
    if (endDate <= 0) {
      endMonthOffset = -1;
      if (endDate == 0) {
        _billingEndDay = 31;
      } else {
        _billingEndDay = 31 + endDate; 
      }
    } else {
      endMonthOffset = 0;
      _billingEndDay = endDate;
    }

    _billingEndMonth = endMonthOffset;

    if (_billingEndDay == 31) {
      _billingStartDay = 1;
      _billingStartMonth = _billingEndMonth; 
    } else {
      _billingStartDay = _billingEndDay + 1;
      _billingStartMonth = _billingEndMonth - 1;
    }
    
    // Show a snackbar feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_bank 결제일($_paymentDay일) 기준 이용기간이 자동 설정되었습니다.', style: GoogleFonts.notoSansKr()),
        backgroundColor: const Color(0xFF4F46E5),
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
      billingStartMonth: _type == 'credit' ? _billingStartMonth : null,
      billingStartDay: _type == 'credit' ? _billingStartDay : null,
      billingEndMonth: _type == 'credit' ? _billingEndMonth : null,
      billingEndDay: _type == 'credit' ? _billingEndDay : null,
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
