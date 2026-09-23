import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../models/account.dart';
import '../../../../../../utils/helpers.dart';
import '../constants/account_constants.dart';

class AddAccountSheetUi extends StatefulWidget {
  final Account? editAccount;
  final List<Account> bankAccounts;
  final void Function(Account account) onSave;

  const AddAccountSheetUi({
    super.key,
    this.editAccount,
    required this.bankAccounts,
    required this.onSave,
  });

  @override
  State<AddAccountSheetUi> createState() => _AddAccountSheetUiState();
}

class _AddAccountSheetUiState extends State<AddAccountSheetUi> {
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

  @override
  void initState() {
    super.initState();
    if (widget.editAccount != null) {
      final acc = widget.editAccount!;
      _type = acc.cardKind ?? 'bank';
      String b = acc.bank;
      if (b == '국민은행') b = 'KB국민은행';
      if (b == '농협은행') b = 'NH농협은행';
      if (b == '기업은행') b = 'IBK기업은행';
      if (b == '국민카드') b = 'KB국민카드';
      if (b == '농협카드') b = 'NH농협카드';
      _bank = b;
      _nameCtrl.text = acc.name;
      _balanceCtrl.text = formatNumber(acc.initialBalance);
      _paymentDay = acc.paymentDay ?? 25;
      _billingStartMonth = acc.billingStartMonth ?? -1;
      _billingStartDay = acc.billingStartDay ?? 1;
      _billingEndMonth = acc.billingEndMonth ?? -1;
      _billingEndDay = acc.billingEndDay ?? 31;
      _linkedBankId = acc.linkedBankAccountId;
      _color = acc.color;
    } else {
      // Set default linked bank if adding new card
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_type == 'credit' || _type == 'debit') {
          if (widget.bankAccounts.isNotEmpty) {
            setState(() {
              _linkedBankId = widget.bankAccounts.first.id;
            });
          }
        }
      });
    }
  }

  void _changeType(String newType) {
    setState(() {
      _type = newType;
      final bankList = _type == 'bank' ? AccountConstants.banks : AccountConstants.cards;
      _bank = bankList[0];
      if (_type == 'credit' || _type == 'debit') {
        if (widget.bankAccounts.isNotEmpty) {
          _linkedBankId = widget.bankAccounts.first.id;
        } else {
          _linkedBankId = null;
        }
      } else {
        _linkedBankId = null;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bankList = _type == 'bank' ? AccountConstants.banks : AccountConstants.cards;
    
    String? validLinkedBankId = _linkedBankId;
    if (validLinkedBankId != null && !widget.bankAccounts.any((b) => b.id == validLinkedBankId)) {
      validLinkedBankId = null;
    }

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
            _BankSelectorRow(
              bankList: bankList,
              selectedBank: _bank,
              onBankSelected: (b) => setState(() => _bank = b),
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
            if (_type == 'credit' || _type == 'debit') ...[
              const SizedBox(height: 14),
              Text(_type == 'debit' ? '연결 통장' : '결제 출금 통장', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
              const SizedBox(height: 6),
              if (widget.bankAccounts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                  child: Text('등록된 통장 목록이 없습니다. 먼저 통장을 추가해주세요.', style: GoogleFonts.notoSansKr(fontSize: 13, color: const Color(0xFF94A3B8))),
                )
              else
                DropdownButtonFormField<String>(
                  value: validLinkedBankId,
                  dropdownColor: const Color(0xFFFFFFFF),
                  style: GoogleFonts.notoSansKr(color: const Color(0xFF0F172A)),
                  decoration: _inputDec('통장을 선택해주세요'),
                  items: [
                    ...widget.bankAccounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                  ],
                  onChanged: (v) => setState(() => _linkedBankId = v),
                ),
            ],
            const SizedBox(height: 14),
            Text('테마 색상', style: GoogleFonts.notoSansKr(fontSize: 11, color: const Color(0xFF64748B))),
            const SizedBox(height: 8),
            _ColorSelectorRow(
              selectedColor: _color,
              onColorSelected: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 20),
          ],
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
      child: InkWell(
        onTap: () => _changeType(type),
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

    String? finalLinkedId = _linkedBankId;
    if (finalLinkedId != null) {
      final bankExists = widget.bankAccounts.any((a) => a.id == finalLinkedId);
      if (!bankExists) finalLinkedId = null;
    }

    if ((_type == 'credit' || _type == 'debit') && finalLinkedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('연결할 통장을 선택해주세요', style: GoogleFonts.notoSansKr())));
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
      linkedBankAccountId: (_type == 'credit' || _type == 'debit') ? finalLinkedId : null,
    );

    widget.onSave(acc);
  }
}

class _BankSelectorRow extends StatelessWidget {
  final List<String> bankList;
  final String selectedBank;
  final ValueChanged<String> onBankSelected;

  const _BankSelectorRow({
    required this.bankList,
    required this.selectedBank,
    required this.onBankSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: bankList.map((b) {
          final isActive = selectedBank == b;
          return GestureDetector(
            onTap: () => onBankSelected(b),
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
    );
  }

  Widget _buildLogo(String name) {
    final url = AccountConstants.logoUrls[name];
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
}

class _ColorSelectorRow extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const _ColorSelectorRow({
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AccountConstants.themeColors.map((c) {
        final isActive = selectedColor == c;
        return GestureDetector(
          onTap: () => onColorSelected(c),
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
    );
  }
}
