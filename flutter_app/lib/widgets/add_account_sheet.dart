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
                      child: Center(child: Text(b, style: GoogleFonts.notoSansKr(fontSize: 11, color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF64748B)))),
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
